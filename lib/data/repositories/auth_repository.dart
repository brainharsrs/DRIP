import '../models/user.dart';

enum AuthField { name, email, password }

/// Erro de autenticação já com a mensagem pronta para a pessoa ler
/// (o que houve + como resolver).
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.field});

  final String message;

  /// Campo do formulário ao qual o erro se refere, quando houver.
  final AuthField? field;

  @override
  String toString() => 'AuthFailure($message)';
}

/// Contrato de autenticação. Existem duas implementações:
/// `FirebaseAuthRepository` (produção) e `LocalAuthRepository` (demonstração).
abstract interface class AuthRepository {
  /// Emite o usuário atual e cada mudança de sessão (`null` = deslogado).
  Stream<AppUser?> authState();

  AppUser? get currentUser;

  /// `true` quando há envio real de e-mail de recuperação de senha.
  bool get canResetPassword;

  /// `true` quando dá para entrar com a conta Google (só com Firebase).
  bool get canUseGoogle;

  /// `true` quando a conta atual tem senha (criada por e-mail). Contas que
  /// entraram só pelo Google confirmam ações sensíveis pelo próprio Google.
  bool get hasPassword;

  Future<void> signIn({required String email, required String password});

  /// Entra (ou cria a conta) com o Google. Se a pessoa fechar a janela do
  /// Google, termina sem erro e sem sessão.
  Future<void> signInWithGoogle();

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> updateName(String name);

  Future<void> signOut();

  /// Apaga a conta. Exige a senha para confirmar que é a própria pessoa;
  /// em contas sem senha ([hasPassword] falso) a confirmação é pelo Google e
  /// [password] é ignorada.
  Future<void> deleteAccount({required String password});
}
