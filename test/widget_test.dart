// Teste de fumaça: o app abre em modo demonstração e mostra a primeira tela.

import 'package:flutter_test/flutter_test.dart';

import 'app_flow_test.dart' show pumpDrip;

void main() {
  testWidgets('o app abre na apresentação, com a opção de pular', (
    tester,
  ) async {
    await pumpDrip(tester);
    expect(find.text('Pular'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });
}
