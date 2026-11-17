import 'package:drip/app/app.dart';
import 'package:drip/data/providers.dart';
import 'package:drip/features/want_list/widgets/save_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abre o app inteiro em modo demonstração, num "celular" de 390×844.
///
/// O teste liga "reduzir movimento": as animações contínuas (letreiro, selo,
/// pulso) ficam paradas e o `pumpAndSettle` consegue terminar.
Future<List<Uri>> pumpDrip(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final opened = <Uri>[];

  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sp),
        firebaseReadyProvider.overrideWithValue(false),
        linkOpenerProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
      child: const DripApp(),
    ),
  );
  // Deixa a abertura terminar.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return opened;
}

/// Cria uma conta pela interface e chega ao Discover.
Future<void> signUp(WidgetTester tester) async {
  await tester.tap(find.text('Pular'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Criar conta'));
  await tester.pumpAndSettle();

  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Alex Teste');
  await tester.enterText(fields.at(1), 'alex@drip.test');
  await tester.enterText(fields.at(2), 'senha-forte-1');
  await tester.ensureVisible(find.text('Criar conta'));
  await tester.tap(find.text('Criar conta'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('primeira abertura: abertura → onboarding → login', (
    tester,
  ) async {
    await pumpDrip(tester);

    // Onboarding na primeira vez.
    expect(find.text('Um só radar para'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);

    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    // Sem sessão, cai no login.
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
  });

  testWidgets('quem já viu o onboarding vai direto ao login', (tester) async {
    await pumpDrip(tester, prefs: {'drip.onboarded': true});
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Continuar'), findsNothing);
  });

  testWidgets('login valida os campos antes de enviar', (tester) async {
    await pumpDrip(tester, prefs: {'drip.onboarded': true});

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Digite seu e-mail.'), findsOneWidget);
    expect(find.text('Digite sua senha.'), findsOneWidget);

    // Conta inexistente: mensagem clara, sem travar a tela.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ninguem@drip.test');
    await tester.enterText(fields.at(1), 'qualquer-senha');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('E-mail ou senha incorretos'), findsOneWidget);
  });

  testWidgets('cadastro leva ao Discover com o feed carregado', (tester) async {
    await pumpDrip(tester);
    await signUp(tester);

    expect(find.text('Descobrir'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Próximos drops'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Próximos drops'), findsOneWidget);
    expect(find.text('Ao vivo agora'), findsOneWidget);
  });

  testWidgets('salvar um drop o coloca na Want List e gera atividade', (
    tester,
  ) async {
    await pumpDrip(tester);
    await signUp(tester);

    // Want List começa vazia.
    await tester.tap(find.text('Want List'));
    await tester.pumpAndSettle();
    expect(find.text('Nada salvo ainda'), findsOneWidget);

    // Salva o destaque ao vivo, direto do pôster do Discover.
    await tester.tap(find.text('Descobrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SaveButton).first);
    await tester.pumpAndSettle();

    // A página já visitada continua montada: o último "Want List" é a aba.
    await tester.tap(find.text('Want List').last);
    await tester.pumpAndSettle();
    expect(find.text('Nada salvo ainda'), findsNothing);
    // O nome também aparece no Discover, que continua montado atrás.
    expect(find.text("Liga 'Prata Fria'"), findsWidgets);

    // O drop salvo está ao vivo: vira aviso na central de atividades.
    await tester.tap(find.text('Atividade'));
    await tester.pumpAndSettle();
    expect(find.text("Liga 'Prata Fria' está ao vivo"), findsOneWidget);

    // Marcar como lidas tira o botão de cena.
    await tester.tap(find.text('Marcar como lidas'));
    await tester.pumpAndSettle();
    expect(find.text('Marcar como lidas'), findsNothing);
  });

  testWidgets('detalhe do drop abre o site oficial da marca', (tester) async {
    final opened = await pumpDrip(tester);
    await signUp(tester);

    await tester.tap(
      find.bySemanticsLabel(RegExp('^Liga .Prata Fria.,')).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Comprar no site da marca'), findsOneWidget);
    await tester.tap(find.text('Comprar no site da marca'));
    await tester.pumpAndSettle();

    expect(opened.single.host, 'example.com');
  });

  testWidgets('busca do Explore encontra marcas e lançamentos', (tester) async {
    await pumpDrip(tester);
    await signUp(tester);

    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    expect(find.text('Marcas'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'vertice');
    await tester.pumpAndSettle();
    expect(find.text('4 resultados'), findsOneWidget);
    expect(find.text('Vértice'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('Nada encontrado'), findsOneWidget);
  });

  testWidgets('sair da conta volta para o login', (tester) async {
    await pumpDrip(tester);
    await signUp(tester);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Teste'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sair'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    // Confirmação numa folha inferior.
    expect(find.text('Sair da conta?'), findsOneWidget);
    await tester.tap(find.text('Sair').last);
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
  });
}
