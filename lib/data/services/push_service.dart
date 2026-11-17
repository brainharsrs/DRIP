import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

enum PushStatus {
  /// Não há push neste ambiente (modo demonstração, web ou sem suporte).
  unavailable,

  /// A pessoa ainda não foi consultada.
  notAsked,

  /// A pessoa negou a permissão nas configurações do sistema.
  denied,

  /// Este aparelho está registrado para receber notificações.
  enabled,
}

class PushMessage {
  const PushMessage({required this.title, required this.body, this.dropId});
  final String title;
  final String body;
  final String? dropId;
}

/// Notificações push (Firebase Cloud Messaging).
abstract interface class PushService {
  Future<PushStatus> status();

  /// Pede a permissão do sistema e registra este aparelho para [uid].
  /// Chame só a partir de uma ação da pessoa (nunca na abertura do app).
  Future<PushStatus> enable(String uid);

  Future<void> disable(String uid);

  /// Mensagens que chegam com o app aberto.
  Stream<PushMessage> get foreground;
}

/// Modo demonstração: não existe push sem Firebase. Nada é simulado.
class NoPushService implements PushService {
  const NoPushService();

  @override
  Future<PushStatus> status() async => PushStatus.unavailable;

  @override
  Future<PushStatus> enable(String uid) async => PushStatus.unavailable;

  @override
  Future<void> disable(String uid) async {}

  @override
  Stream<PushMessage> get foreground => const Stream.empty();
}

/// Registro do aparelho no FCM.
///
/// O identificador de envio fica em `users/{uid}/tokens/{id}`; é de lá que o
/// servidor (Cloud Functions) lê para quem mandar cada aviso.
/// Enviar notificações exige um backend, que ainda não existe: veja FIREBASE.md.
class FirebasePushService implements PushService {
  FirebasePushService(this._messaging, this._db);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;
  StreamSubscription<String>? _registered;

  CollectionReference<Map<String, dynamic>> _tokens(String uid) =>
      _db.collection('users').doc(uid).collection('tokens');

  static PushStatus _map(AuthorizationStatus s) => switch (s) {
    AuthorizationStatus.authorized ||
    AuthorizationStatus.provisional => PushStatus.enabled,
    AuthorizationStatus.denied => PushStatus.denied,
    _ => PushStatus.notAsked,
  };

  @override
  Future<PushStatus> status() async {
    // Na web o FCM exige chave VAPID e service worker próprios (fora do MVP).
    if (kIsWeb || !await _messaging.isSupported()) {
      return PushStatus.unavailable;
    }
    final settings = await _messaging.getNotificationSettings();
    return _map(settings.authorizationStatus);
  }

  @override
  Future<PushStatus> enable(String uid) async {
    if (kIsWeb || !await _messaging.isSupported()) {
      return PushStatus.unavailable;
    }
    final settings = await _messaging.requestPermission();
    final status = _map(settings.authorizationStatus);
    if (status != PushStatus.enabled) return status;

    await _registered?.cancel();
    _registered = _messaging.onRegistered.listen((id) {
      _tokens(uid).doc(id).set({
        'id': id,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    await _messaging.register();
    return PushStatus.enabled;
  }

  @override
  Future<void> disable(String uid) async {
    await _registered?.cancel();
    _registered = null;
    final gone = _messaging.onUnregistered.first.timeout(
      const Duration(seconds: 10),
    );
    await _messaging.unregister();
    try {
      await _tokens(uid).doc(await gone).delete();
    } on TimeoutException {
      // Sem confirmação do FCM: o registro expira sozinho no servidor.
    }
  }

  @override
  Stream<PushMessage> get foreground => FirebaseMessaging.onMessage.map(
    (m) => PushMessage(
      title: m.notification?.title ?? '',
      body: m.notification?.body ?? '',
      dropId: m.data['dropId'] as String?,
    ),
  );
}
