import 'package:drip/data/models/user.dart';
import 'package:drip/data/repositories/auth_repository.dart';
import 'package:drip/data/repositories/local_auth_repository.dart';
import 'package:drip/data/repositories/user_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Autenticação local (modo demonstração)', () {
    test('cadastro abre a sessão e ela persiste entre aberturas', () async {
      final repo = LocalAuthRepository(prefs);
      expect(repo.currentUser, isNull);

      await repo.signUp(
        name: ' Alex ',
        email: 'Alex@Drip.test',
        password: 'senha-forte-1',
      );
      expect(repo.currentUser?.name, 'Alex');
      expect(repo.currentUser?.email, 'alex@drip.test');

      // Um novo repositório simula fechar e abrir o app.
      final reopened = LocalAuthRepository(prefs);
      expect(reopened.currentUser?.email, 'alex@drip.test');
    });

    test('a senha nunca é gravada em texto puro', () async {
      await LocalAuthRepository(
        prefs,
      ).signUp(name: 'Alex', email: 'a@drip.test', password: 'senha-forte-1');
      final stored = prefs.getString('drip.accounts')!;
      expect(stored.contains('senha-forte-1'), isFalse);
    });

    test('não permite duas contas com o mesmo e-mail', () async {
      final repo = LocalAuthRepository(prefs);
      await repo.signUp(name: 'A', email: 'a@drip.test', password: '12345678');
      await repo.signOut();
      expect(
        () =>
            repo.signUp(name: 'B', email: 'A@DRIP.test', password: '87654321'),
        throwsA(
          isA<AuthFailure>().having((e) => e.field, 'field', AuthField.email),
        ),
      );
    });

    test('login: senha certa entra, senha errada é recusada', () async {
      final repo = LocalAuthRepository(prefs);
      await repo.signUp(name: 'A', email: 'a@drip.test', password: '12345678');
      await repo.signOut();
      expect(repo.currentUser, isNull);

      expect(
        () => repo.signIn(email: 'a@drip.test', password: 'errada'),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        () => repo.signIn(email: 'ninguem@drip.test', password: '12345678'),
        throwsA(isA<AuthFailure>()),
      );

      await repo.signIn(email: 'a@drip.test', password: '12345678');
      expect(repo.currentUser?.email, 'a@drip.test');
    });

    test('o stream avisa cada mudança de sessão', () async {
      final repo = LocalAuthRepository(prefs);
      final seen = <String?>[];
      final sub = repo.authState().listen((u) => seen.add(u?.email));

      await repo.signUp(name: 'A', email: 'a@drip.test', password: '12345678');
      await repo.signOut();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(seen, [null, 'a@drip.test', null]);
    });

    test('trocar o nome e sair', () async {
      final repo = LocalAuthRepository(prefs);
      await repo.signUp(name: 'A', email: 'a@drip.test', password: '12345678');
      await repo.updateName('Novo Nome');
      expect(repo.currentUser?.name, 'Novo Nome');
      expect(LocalAuthRepository(prefs).currentUser?.name, 'Novo Nome');

      await repo.signOut();
      expect(LocalAuthRepository(prefs).currentUser, isNull);
    });

    test('excluir a conta exige a senha correta', () async {
      final repo = LocalAuthRepository(prefs);
      await repo.signUp(name: 'A', email: 'a@drip.test', password: '12345678');

      expect(
        () => repo.deleteAccount(password: 'errada'),
        throwsA(isA<AuthFailure>()),
      );
      expect(repo.currentUser, isNotNull);

      await repo.deleteAccount(password: '12345678');
      expect(repo.currentUser, isNull);
      expect(
        () => repo.signIn(email: 'a@drip.test', password: '12345678'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('recuperação de senha não finge funcionar sem servidor', () async {
      final repo = LocalAuthRepository(prefs);
      expect(repo.canResetPassword, isFalse);
      expect(
        () => repo.sendPasswordReset('a@drip.test'),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('Dados do usuário (modo demonstração)', () {
    test('Want List: salvar, remover e persistir', () async {
      final repo = LocalUserDataRepository(prefs);
      await repo.setWant('u1', 'drop-a', true);
      await repo.setWant('u1', 'drop-b', true);
      await repo.setWant('u1', 'drop-a', false);

      final data = await LocalUserDataRepository(prefs).watch('u1').first;
      expect(data.wantList, {'drop-b'});
    });

    test('cada usuário só enxerga os próprios dados', () async {
      final repo = LocalUserDataRepository(prefs);
      await repo.setWant('u1', 'drop-a', true);
      await repo.setFollow('u2', 'marca-x', true);

      expect((await repo.watch('u1').first).following, isEmpty);
      expect((await repo.watch('u2').first).wantList, isEmpty);
      expect((await repo.watch('u2').first).follows('marca-x'), isTrue);
    });

    test('o stream emite o estado atual e cada alteração', () async {
      final repo = LocalUserDataRepository(prefs);
      final sizes = <int>[];
      final sub = repo.watch('u1').listen((d) => sizes.add(d.wantList.length));

      await repo.setWant('u1', 'a', true);
      await repo.setWant('u1', 'b', true);
      await repo.setWant('u1', 'a', false);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(sizes, [0, 1, 2, 1]);
    });

    test('interesses, preferências de aviso e lidas', () async {
      final repo = LocalUserDataRepository(prefs);
      await repo.setInterest('u1', 'sneakers', true);
      await repo.setNotifPref('u1', NotifPref.liveNow, false);
      await repo.markRead('u1', ['x', 'y']);
      await repo.markRead('u1', ['y', 'z']);

      final d = await repo.watch('u1').first;
      expect(d.interests, {'sneakers'});
      expect(d.notifEnabled(NotifPref.liveNow), isFalse);
      expect(d.notifEnabled(NotifPref.savedDrops), isTrue);
      expect(d.readActivity, {'x', 'y', 'z'});

      await repo.setNotifPref('u1', NotifPref.liveNow, true);
      expect(
        (await repo.watch('u1').first).notifEnabled(NotifPref.liveNow),
        isTrue,
      );
    });

    test('apagar tudo zera os dados do usuário', () async {
      final repo = LocalUserDataRepository(prefs);
      await repo.setWant('u1', 'a', true);
      await repo.deleteAll('u1');
      expect((await repo.watch('u1').first).wantList, isEmpty);
    });
  });
}
