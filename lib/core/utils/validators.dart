/// Validações de formulário. Cada função devolve a mensagem de erro
/// (já dizendo como corrigir) ou `null` quando o valor é válido.
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static const minPassword = 8;

  static String? name(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Digite seu nome.';
    if (t.length < 2) return 'O nome precisa de pelo menos 2 letras.';
    if (t.length > 60) return 'Use no máximo 60 caracteres.';
    return null;
  }

  static String? email(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Digite seu e-mail.';
    if (!_email.hasMatch(t)) {
      return 'Confira o e-mail: falta algo como nome@site.com.';
    }
    return null;
  }

  /// Para login: só exige que exista.
  static String? passwordRequired(String? v) =>
      (v == null || v.isEmpty) ? 'Digite sua senha.' : null;

  /// Para cadastro: exige tamanho mínimo.
  static String? newPassword(String? v) {
    if (v == null || v.isEmpty) return 'Crie uma senha.';
    if (v.length < minPassword) {
      return 'Use pelo menos $minPassword caracteres.';
    }
    return null;
  }
}
