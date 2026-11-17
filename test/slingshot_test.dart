import 'package:drip/core/theme/app_theme.dart';
import 'package:drip/features/want_list/widgets/want_list_slingshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback onAdded,
  VoidCallback? onDone,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: WantListSlingshot(
              onAddedToWantList: onAdded,
              onCycleComplete: onDone,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // Bolinha parada: centro horizontal, 96 px acima da base (altura 300).
  Offset ball(WidgetTester tester) {
    final box = tester.getRect(find.byType(WantListSlingshot));
    return Offset(box.center.dx, box.top + 300 - 96);
  }

  testWidgets('puxão forte lança, salva e a bolinha volta', (tester) async {
    var added = 0;
    var done = 0;
    await _pump(tester, onAdded: () => added++, onDone: () => done++);

    final g = await tester.startGesture(ball(tester));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(0, 14));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pump();
    expect(added, 1);

    // Voo + confirmação + reaparecimento.
    for (var i = 0; i < 180; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(done, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('puxão fraco não salva', (tester) async {
    var added = 0;
    await _pump(tester, onAdded: () => added++);

    final g = await tester.startGesture(ball(tester));
    await g.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 16));
    await g.up();
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(added, 0);
  });

  testWidgets('arrastar fora da bolinha não faz nada', (tester) async {
    var added = 0;
    await _pump(tester, onAdded: () => added++);

    final g = await tester.startGesture(ball(tester) + const Offset(120, 0));
    await g.moveBy(const Offset(0, 140));
    await g.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(added, 0);
  });
}
