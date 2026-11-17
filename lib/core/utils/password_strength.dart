/// Requisitos mostrados no checklist da senha.
///
/// São uma orientação visual: a regra que de fato barra o cadastro continua
/// sendo `Validators.newPassword`.
enum PasswordRule {
  length('8 caracteres ou mais'),
  upper('Uma letra maiúscula'),
  number('Um número'),
  special('Um caractere especial (!@#\$...)');

  const PasswordRule(this.label);
  final String label;
}

abstract final class PasswordStrength {
  static const minLength = 8;
  static const maxScore = 4;

  static final _upper = RegExp(r'\p{Lu}', unicode: true);
  static final _number = RegExp(r'\d');
  static final _special = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  /// Requisitos já atendidos pela senha.
  static Set<PasswordRule> met(String v) => {
    if (v.length >= minLength) PasswordRule.length,
    if (_upper.hasMatch(v)) PasswordRule.upper,
    if (_number.hasMatch(v)) PasswordRule.number,
    if (_special.hasMatch(v)) PasswordRule.special,
  };

  /// Força de 0 (vazia) a 4 (todos os requisitos). Uma senha curta nunca
  /// passa de 2, por mais variada que seja.
  static int score(String v) {
    if (v.isEmpty) return 0;
    final rules = met(v);
    final n = rules.isEmpty ? 1 : rules.length;
    return rules.contains(PasswordRule.length) ? n : (n > 2 ? 2 : n);
  }

  static String label(int score) => switch (score) {
    0 => 'Pelo menos $minLength caracteres',
    1 => 'Fraca',
    2 => 'Razoável',
    3 => 'Boa',
    _ => 'Forte',
  };
}
