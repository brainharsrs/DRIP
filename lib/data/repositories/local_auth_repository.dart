import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/streams.dart';
import 'auth_repository.dart';

/// Autenticação do **modo demonstração**: contas guardadas só neste aparelho.
///
/// Serve para desenvolver e testar os fluxos sem depender do Firebase.
/// Não é um sistema de autenticação de produção: não há servidor, não há
/// recuperação de senha por e-mail e os dados não saem do dispositivo.
/// (A senha nunca é gravada em texto puro: fica só o hash com sal.)
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._prefs) {
    _current = _restore();
  }

  final SharedPreferences _prefs;
  final _changes = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  static const _kAccounts = 'drip.accounts';
  static const _kSession = 'drip.session';

  Map<String, dynamic> _accounts() {
    final raw = _prefs.getString(_kAccounts);
    return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _saveAccounts(Map<String, dynamic> accounts) =>
      _prefs.setString(_kAccounts, jsonEncode(accounts));

  AppUser? _restore() {
    final uid = _prefs.getString(_kSession);
    if (uid == null) return null;
    for (final entry in _accounts().entries) {
      final m = entry.value as Map<String, dynamic>;
      if (m['uid'] == uid) {
        return AppUser(uid: uid, name: m['name'] as String, email: entry.key);
      }
    }
    return null;
  }

  static String _key(String email) => email.trim().toLowerCase();

  static String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  static String _newSalt() {
    final rnd = Random.secure();
    return base64Url.encode(List.generate(16, (_) => rnd.nextInt(256)));
  }

  Future<void> _setSession(AppUser? user) async {
    _current = user;
    _changes.add(user);
    if (user == null) {
      await _prefs.remove(_kSession);
    } else {
      await _prefs.setString(_kSession, user.uid);
    }
  }

  @override
  Stream<AppUser?> authState() => seededStream(() => _current, _changes.stream);

  @override
  AppUser? get currentUser => _current;

  @override
  bool get canResetPassword => false;

  @override
  bool get canUseGoogle => false;

  @override
  bool get hasPassword => true;

  @override
  Future<void> signInWithGoogle() async => throw const AuthFailure(
    'O login com Google só funciona com o servidor configurado.',
  );

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final accounts = _accounts();
    final key = _key(email);
    if (accounts.containsKey(key)) {
      throw const AuthFailure(
        'Já existe uma conta com este e-mail. Entre ou use outro e-mail.',
        field: AuthField.email,
      );
    }
    final salt = _newSalt();
    final uid = 'local_${DateTime.now().microsecondsSinceEpoch}';
    accounts[key] = {
      'uid': uid,
      'name': name.trim(),
      'salt': salt,
      'hash': _hash(password, salt),
    };
    await _saveAccounts(accounts);
    await _setSession(AppUser(uid: uid, name: name.trim(), email: key));
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final key = _key(email);
    final m = _accounts()[key] as Map<String, dynamic>?;
    if (m == null || m['hash'] != _hash(password, m['salt'] as String)) {
      throw const AuthFailure(
        'E-mail ou senha incorretos. Confira os dados e tente de novo.',
      );
    }
    await _setSession(
      AppUser(uid: m['uid'] as String, name: m['name'] as String, email: key),
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    throw const AuthFailure(
      'No modo demonstração não há envio de e-mail. A recuperação de senha '
      'passa a funcionar quando o Firebase estiver configurado. Por enquanto, '
      'crie uma nova conta.',
    );
  }

  @override
  Future<void> updateName(String name) async {
    final user = _current;
    if (user == null) return;
    final accounts = _accounts();
    final m = accounts[user.email] as Map<String, dynamic>?;
    if (m == null) return;
    m['name'] = name.trim();
    await _saveAccounts(accounts);
    await _setSession(
      AppUser(uid: user.uid, name: name.trim(), email: user.email),
    );
  }

  @override
  Future<void> signOut() => _setSession(null);

  @override
  Future<void> deleteAccount({required String password}) async {
    final user = _current;
    if (user == null) return;
    final accounts = _accounts();
    final m = accounts[user.email] as Map<String, dynamic>?;
    if (m != null && m['hash'] != _hash(password, m['salt'] as String)) {
      throw const AuthFailure(
        'Senha incorreta. Digite a senha desta conta para confirmar.',
        field: AuthField.password,
      );
    }
    accounts.remove(user.email);
    await _saveAccounts(accounts);
    await _setSession(null);
  }
}
