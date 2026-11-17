import 'package:drip/features/shell/app_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_flow_test.dart';

int _shown(WidgetTester tester) =>
    tester.widget<BranchSwitcher>(find.byType(BranchSwitcher)).index;

int _barIndex(WidgetTester tester) =>
    tester.widget<DripTabBar>(find.byType(DripTabBar)).index;

double _opacity(WidgetTester tester, int branch) => tester
    .widget<FadeTransition>(
      find
          .descendant(
            of: find.byKey(ValueKey('branch-$branch')),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

void main() {
  testWidgets('abas continuam trocando depois de abrir as Configurações', (
    tester,
  ) async {
    await pumpDrip(tester);
    await signUp(tester);

    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    expect(_shown(tester), 4);

    await tester.tap(find.bySemanticsLabel('Configurações'));
    await tester.pumpAndSettle();
    expect(find.text('Configurações'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Voltar'));
    await tester.pumpAndSettle();

    for (final (label, i) in [
      ('Descobrir', 0),
      ('Explorar', 1),
      ('Want List', 2),
      ('Atividade', 3),
      ('Perfil', 4),
    ]) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(_barIndex(tester), i, reason: 'barra em $label');
      expect(_shown(tester), i, reason: 'conteúdo em $label');
      // Só a aba ativa pode estar visível: as outras precisam ter sumido.
      for (var b = 0; b < 5; b++) {
        expect(_opacity(tester, b), b == i ? 1.0 : 0.0, reason: 'aba $b');
      }
    }
  });
}
