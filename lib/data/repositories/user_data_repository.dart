import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/streams.dart';

/// Dados privados de cada pessoa: Want List, marcas acompanhadas,
/// interesses, preferências de notificação e atividades lidas.
abstract interface class UserDataRepository {
  Stream<UserData> watch(String uid);

  Future<void> setWant(String uid, String dropId, bool value);
  Future<void> setFollow(String uid, String brandId, bool value);
  Future<void> setInterest(String uid, String category, bool value);
  Future<void> setNotifPref(String uid, NotifPref pref, bool enabled);
  Future<void> markRead(String uid, Iterable<String> activityIds);

  /// Notificações gravadas pelo servidor (ex.: avisos enviados pela equipe).
  Stream<List<ActivityItem>> watchServerNotifications(String uid);

  /// Apaga tudo o que pertence ao usuário.
  Future<void> deleteAll(String uid);
}

/// Modo demonstração: guarda tudo neste aparelho (não sincroniza).
class LocalUserDataRepository implements UserDataRepository {
  LocalUserDataRepository(this._prefs);

  final SharedPreferences _prefs;
  final _changes = StreamController<(String, UserData)>.broadcast();

  static String _key(String uid) => 'drip.userdata.$uid';

  UserData _read(String uid) => UserData.decode(_prefs.getString(_key(uid)));

  Future<void> _write(String uid, UserData data) async {
    _changes.add((uid, data));
    await _prefs.setString(_key(uid), data.encode());
  }

  static Set<String> _toggle(Set<String> set, String id, bool add) {
    final next = {...set};
    add ? next.add(id) : next.remove(id);
    return next;
  }

  @override
  Stream<UserData> watch(String uid) => seededStream(
    () => _read(uid),
    _changes.stream.where((e) => e.$1 == uid).map((e) => e.$2),
  );

  @override
  Future<void> setWant(String uid, String dropId, bool value) {
    final d = _read(uid);
    return _write(
      uid,
      d.copyWith(wantList: _toggle(d.wantList, dropId, value)),
    );
  }

  @override
  Future<void> setFollow(String uid, String brandId, bool value) {
    final d = _read(uid);
    return _write(
      uid,
      d.copyWith(following: _toggle(d.following, brandId, value)),
    );
  }

  @override
  Future<void> setInterest(String uid, String category, bool value) {
    final d = _read(uid);
    return _write(
      uid,
      d.copyWith(interests: _toggle(d.interests, category, value)),
    );
  }

  @override
  Future<void> setNotifPref(String uid, NotifPref pref, bool enabled) {
    final d = _read(uid);
    return _write(
      uid,
      d.copyWith(notifOff: _toggle(d.notifOff, pref.name, !enabled)),
    );
  }

  @override
  Future<void> markRead(String uid, Iterable<String> activityIds) {
    final d = _read(uid);
    return _write(
      uid,
      d.copyWith(readActivity: {...d.readActivity, ...activityIds}),
    );
  }

  @override
  Stream<List<ActivityItem>> watchServerNotifications(String uid) =>
      Stream.value(const []);

  @override
  Future<void> deleteAll(String uid) async {
    _changes.add((uid, const UserData()));
    await _prefs.remove(_key(uid));
  }
}

/// Produção: um documento por pessoa em `users/{uid}`, sincronizado em tempo
/// real entre os aparelhos e disponível offline (cache do Firestore).
///
/// As listas ficam em campos de array no próprio documento: uma leitura traz
/// tudo e `arrayUnion`/`arrayRemove` evitam conflitos entre aparelhos.
class FirestoreUserDataRepository implements UserDataRepository {
  FirestoreUserDataRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> _array(String uid, String field, List<String> ids, bool add) =>
      _doc(uid).set({
        field: add ? FieldValue.arrayUnion(ids) : FieldValue.arrayRemove(ids),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  @override
  Stream<UserData> watch(String uid) =>
      _doc(uid).snapshots().map((s) => UserData.fromMap(s.data()));

  @override
  Future<void> setWant(String uid, String dropId, bool value) =>
      _array(uid, 'wantList', [dropId], value);

  @override
  Future<void> setFollow(String uid, String brandId, bool value) =>
      _array(uid, 'following', [brandId], value);

  @override
  Future<void> setInterest(String uid, String category, bool value) =>
      _array(uid, 'interests', [category], value);

  @override
  Future<void> setNotifPref(String uid, NotifPref pref, bool enabled) =>
      _array(uid, 'notifOff', [pref.name], !enabled);

  @override
  Future<void> markRead(String uid, Iterable<String> activityIds) {
    final ids = activityIds.toList();
    if (ids.isEmpty) return Future.value();
    return _array(uid, 'readActivity', ids, true);
  }

  @override
  Stream<List<ActivityItem>> watchServerNotifications(String uid) => _doc(uid)
      .collection('notifications')
      .orderBy('at', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            ActivityItem(
              id: 'srv:${d.id}',
              kind: ActivityKind.system,
              title: (d.data()['title'] ?? '') as String,
              body: (d.data()['body'] ?? '') as String,
              at: (d.data()['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
              dropId: d.data()['dropId'] as String?,
              brandId: d.data()['brandId'] as String?,
            ),
        ],
      );

  @override
  Future<void> deleteAll(String uid) => _doc(uid).delete();
}
