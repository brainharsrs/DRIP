import 'package:drip/core/utils/formatters.dart';
import 'package:drip/core/utils/links.dart';
import 'package:drip/core/utils/validators.dart';
import 'package:drip/data/models/drop.dart';
import 'package:flutter_test/flutter_test.dart';

Drop _drop({DateTime? at, String name = "Arco 01 'Grafite'"}) => Drop(
  id: 'x',
  name: name,
  brandId: 'b',
  brandName: 'Vértice',
  category: DropCategory.sneakers,
  description: '',
  releaseAt: at,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  final now = DateTime(2026, 11, 16, 12);

  group('Status do drop', () {
    test('sem data é "data a definir"', () {
      expect(_drop().statusAt(now), DropStatus.tbd);
    });

    test('antes da data é "em breve"', () {
      final d = _drop(at: now.add(const Duration(minutes: 1)));
      expect(d.statusAt(now), DropStatus.upcoming);
    });

    test('fica "ao vivo" por 24 h a partir da abertura', () {
      expect(_drop(at: now).statusAt(now), DropStatus.live);
      final almost = _drop(at: now.subtract(const Duration(hours: 23)));
      expect(almost.statusAt(now), DropStatus.live);
    });

    test('depois de 24 h vira "lançado"', () {
      final d = _drop(at: now.subtract(const Duration(hours: 25)));
      expect(d.statusAt(now), DropStatus.released);
    });

    test('a palavra do pôster é a primeira do nome', () {
      expect(_drop().poster, 'Arco');
      expect(_drop(name: "Geada 'Cromo × Kalt'").poster, 'Geada');
    });
  });

  group('Links externos', () {
    test('aceita http e https com domínio', () {
      expect(Links.parse('https://example.com/x'), isNotNull);
      expect(Links.parse('  http://www.marca.com.br  '), isNotNull);
    });

    test('recusa vazio, malformado e esquemas perigosos', () {
      expect(Links.parse(null), isNull);
      expect(Links.parse(''), isNull);
      expect(Links.parse('orla-norte/mare'), isNull);
      expect(Links.parse('javascript:alert(1)'), isNull);
      expect(Links.parse('file:///etc/passwd'), isNull);
      expect(Links.parse('https://semdominio'), isNull);
      expect(Links.parse('https://exa mple.com'), isNull);
    });

    test('mostra o domínio sem www', () {
      expect(Links.host(Uri.parse('https://www.marca.com/drop')), 'marca.com');
    });
  });

  group('Validação de formulários', () {
    test('e-mail', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('sem-arroba'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email(' nome@site.com '), isNull);
    });

    test('senha nova exige 8 caracteres', () {
      expect(Validators.newPassword('1234567'), isNotNull);
      expect(Validators.newPassword('12345678'), isNull);
    });

    test('nome', () {
      expect(Validators.name(' '), isNotNull);
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name('Alex'), isNull);
    });
  });

  group('Formatação', () {
    test('preço em reais', () {
      expect(Fmt.price(1299), 'R\$ 1.299,00');
      expect(Fmt.price(899.9), 'R\$ 899,90');
      expect(Fmt.price(1234567.5), 'R\$ 1.234.567,50');
    });

    test('datas', () {
      final d = DateTime(2026, 11, 4, 9, 5);
      expect(Fmt.dayMonth(d), '04 NOV');
      expect(Fmt.time(d), '09:05');
      expect(Fmt.weekday(d), 'QUA');
    });

    test('tempo até abrir', () {
      expect(
        Fmt.untilText(now.add(const Duration(minutes: 30)), now),
        'em 30 min',
      );
      expect(Fmt.untilText(now.add(const Duration(hours: 3)), now), 'em 3 h');
      expect(Fmt.untilText(DateTime(2026, 11, 17, 20), now), 'amanhã');
      expect(Fmt.untilText(DateTime(2026, 11, 21, 10), now), 'em 5 dias');
    });

    test('tempo desde que abriu', () {
      expect(
        Fmt.sinceText(now.subtract(const Duration(minutes: 5)), now),
        'há 5 min',
      );
      expect(
        Fmt.sinceText(now.subtract(const Duration(hours: 2)), now),
        'há 2 h',
      );
      expect(Fmt.sinceText(DateTime(2026, 11, 13, 9), now), 'há 3 dias');
    });

    test('contagem regressiva nunca fica negativa', () {
      final t = Fmt.countdown(const Duration(seconds: -5));
      expect('${t.d}${t.h}${t.m}${t.s}', '00000000');
      final u = Fmt.countdown(
        const Duration(days: 2, hours: 3, minutes: 4, seconds: 5),
      );
      expect((u.d, u.h, u.m, u.s), ('02', '03', '04', '05'));
    });
  });
}
