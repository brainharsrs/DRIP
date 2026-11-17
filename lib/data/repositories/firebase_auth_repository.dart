import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import 'auth_repository.dart';

/// Autenticação de produção: Firebase Authentication (e-mail e senha, e
/// conta Google).
///
/// A sessão persiste sozinha entre aberturas do app (o SDK cuida disso).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._db);

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Seletor de contas do Google no Android/iOS. Na web o login abre uma
  /// janela do próprio Firebase e este objeto não é usado.
  late final _google = GoogleSignIn();

  AppUser? _map(fb.User? u) {
    if (u == null) return null;
    final email = u.email ?? '';
    final display = u.displayName?.trim() ?? '';
    return AppUser(
      uid: u.uid,
      name: display.isNotEmpty ? display : email.split('@').first,
      email: email,
    );
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on fb.FirebaseAuthException catch (e) {
      throw _failure(e);
    } on FirebaseException catch (e) {
      throw AuthFailure(
        'Não foi possível concluir (${e.code}). Tente de novo.',
      );
    }
  }

  static AuthFailure _failure(fb.FirebaseAuthException e) => switch (e.code) {
    'invalid-email' => const AuthFailure(
      'Este e-mail não parece válido. Confira e tente de novo.',
      field: AuthField.email,
    ),
    'user-disabled' => const AuthFailure(
      'Esta conta foi desativada. Fale com o suporte do DRIP.',
    ),
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' ||
    'invalid-login-credentials' => const AuthFailure(
      'E-mail ou senha incorretos. Confira os dados ou redefina a senha.',
    ),
    'email-already-in-use' => const AuthFailure(
      'Já existe uma conta com este e-mail. Entre ou use outro e-mail.',
      field: AuthField.email,
    ),
    'weak-password' => const AuthFailure(
      'Senha fraca. Use pelo menos 8 caracteres.',
      field: AuthField.password,
    ),
    'too-many-requests' => const AuthFailure(
      'Muitas tentativas seguidas. Espere alguns minutos e tente de novo.',
    ),
    'network-request-failed' => const AuthFailure(
      'Sem conexão. Verifique a internet e tente de novo.',
    ),
    'requires-recent-login' => const AuthFailure(
      'Por segurança, saia e entre de novo antes de fazer isso.',
    ),
    'operation-not-allowed' => const AuthFailure(
      'Esta forma de login não está ativada no projeto Firebase.',
    ),
    'account-exists-with-different-credential' => const AuthFailure(
      'Já existe uma conta com este e-mail. Entre com e-mail e senha.',
    ),
    'user-mismatch' => const AuthFailure(
      'Use a mesma conta Google com que você entrou no DRIP.',
    ),
    'popup-blocked' => const AuthFailure(
      'O navegador bloqueou a janela do Google. Libere pop-ups e tente de novo.',
    ),
    _ => AuthFailure('Algo deu errado (${e.code}). Tente de novo.'),
  };

  @override
  Stream<AppUser?> authState() => _auth.userChanges().map(_map);

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  bool get canResetPassword => true;

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  @override
  // O login com Google só tem implementação na web, no Android e no iOS.
  bool get canUseGoogle =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  bool get hasPassword =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  /// Códigos que só significam "a pessoa fechou a janela do Google".
  static const _cancelled = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'web-context-cancelled',
    'web-context-canceled',
    'canceled',
  };

  /// Abre o seletor de contas do Google (Android/iOS) e devolve a
  /// credencial para o Firebase, ou `null` se a pessoa desistir.
  Future<fb.AuthCredential?> _googleCredential() async {
    try {
      final account = await _google.signIn();
      if (account == null) return null;
      final tokens = await account.authentication;
      return fb.GoogleAuthProvider.credential(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') return null;
      if (e.code == 'network_error') {
        throw const AuthFailure(
          'Sem conexão. Verifique a internet e tente de novo.',
        );
      }
      throw AuthFailure(
        'Não foi possível entrar com o Google (${e.code}). Tente de novo.',
      );
    }
  }

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    final fb.UserCredential cred;
    try {
      if (kIsWeb) {
        cred = await _auth.signInWithPopup(fb.GoogleAuthProvider());
      } else {
        final credential = await _googleCredential();
        if (credential == null) return;
        cred = await _auth.signInWithCredential(credential);
      }
    } on fb.FirebaseAuthException catch (e) {
      if (_cancelled.contains(e.code)) return;
      rethrow;
    }
    final user = cred.user;
    if (user == null) return;
    // Primeira vez com esta conta: cria o perfil, como no cadastro.
    final doc = _db.collection('users').doc(user.uid);
    if ((await doc.get()).exists) return;
    final email = user.email ?? '';
    var name = user.displayName?.trim() ?? '';
    if (name.isEmpty) name = email.split('@').first;
    if (name.length > 60) name = name.substring(0, 60);
    await doc.set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) => _guard(() async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) return;
    await user.updateDisplayName(name.trim());
    await _db.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> updateName(String name) => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name.trim());
    await _db.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });

  @override
  Future<void> signOut() => _guard(() async {
    await _auth.signOut();
    if (!kIsWeb) {
      // Solta também a conta Google, para o seletor aparecer na próxima vez.
      try {
        await _google.signOut();
      } catch (_) {}
    }
  });

  @override
  Future<void> deleteAccount({required String password}) => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) return;
    // Confirma a identidade antes de uma ação irreversível.
    if (hasPassword) {
      final email = user.email;
      if (email == null) return;
      await user.reauthenticateWithCredential(
        fb.EmailAuthProvider.credential(email: email, password: password),
      );
    } else if (kIsWeb) {
      try {
        await user.reauthenticateWithPopup(fb.GoogleAuthProvider());
      } on fb.FirebaseAuthException catch (e) {
        if (_cancelled.contains(e.code)) {
          throw const AuthFailure('Confirmação cancelada. Nada foi apagado.');
        }
        rethrow;
      }
    } else {
      final credential = await _googleCredential();
      if (credential == null) {
        throw const AuthFailure('Confirmação cancelada. Nada foi apagado.');
      }
      await user.reauthenticateWithCredential(credential);
    }
    final doc = _db.collection('users').doc(user.uid);
    // Apagar o documento não apaga as subcoleções: elas vão uma a uma.
    for (final sub in const ['tokens', 'notifications']) {
      final items = await doc.collection(sub).get();
      for (final item in items.docs) {
        await item.reference.delete();
      }
    }
    await doc.delete();
    await user.delete();
  });
}
