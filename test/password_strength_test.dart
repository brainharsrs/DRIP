import 'package:drip/core/utils/password_strength.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordStrength', () {
    test('senha vazia tem força 0 e nenhum requisito', () {
      expect(PasswordStrength.score(''), 0);
      expect(PasswordStrength.met(''), isEmpty);
    });

    test('cada requisito é reconhecido', () {
      expect(PasswordStrength.met('abcdefgh'), {PasswordRule.length});
      expect(PasswordStrength.met('A'), {PasswordRule.upper});
      expect(PasswordStrength.met('É'), {PasswordRule.upper});
      expect(PasswordStrength.met('7'), {PasswordRule.number});
      expect(PasswordStrength.met('!'), {PasswordRule.special});
      // Letra acentuada e espaço não contam como caractere especial.
      expect(PasswordStrength.met('ção e'), isEmpty);
    });

    test('a força sobe com os requisitos', () {
      expect(PasswordStrength.score('abc'), 1);
      expect(PasswordStrength.score('abcdefgh'), 1);
      expect(PasswordStrength.score('Abcdefgh'), 2);
      expect(PasswordStrength.score('Abcdefg1'), 3);
      expect(PasswordStrength.score('Abcdef1!'), 4);
    });

    test('senha curta nunca passa de 2', () {
      expect(PasswordStrength.score('A1!'), 2);
    });

    test('todo nível tem um texto de status', () {
      for (var s = 0; s <= PasswordStrength.maxScore; s++) {
        expect(PasswordStrength.label(s), isNotEmpty);
      }
      expect(PasswordStrength.label(4), 'Forte');
    });
  });
}
