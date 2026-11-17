import 'package:drip/app/router.dart';
import 'package:drip/data/demo/demo_catalog.dart';
import 'package:drip/data/models/drop.dart';
import 'package:drip/data/models/user.dart';
import 'package:drip/features/activity/activity_logic.dart';
import 'package:drip/features/discover/feed.dart';
import 'package:drip/features/explore/explore_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 16, 12);
  final drops = DemoCatalog.drops(now);
  const brands = DemoCatalog.brands;

  group('Feed do Discover', () {
    final feed = Feed.from(drops, now);

    test('separa por momento', () {
      expect(feed.live.map((d) => d.id), ['cromo-liga-prata-fria']);
      expect(feed.tbd.length, 2);
      expect(feed.released.length, 3);
      expect(
        feed.live.length +
            feed.upcoming.length +
            feed.tbd.length +
            feed.released.length,
        drops.length,
      );
    });

    test('próximos em ordem cronológica', () {
      final dates = feed.upcoming.map((d) => d.releaseAt!).toList();
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].isBefore(dates[i - 1]), isFalse);
      }
    });

    test('lançados do mais recente ao mais antigo', () {
      final dates = feed.released.map((d) => d.releaseAt!).toList();
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].isAfter(dates[i - 1]), isFalse);
      }
    });

    test('destaques começam pelo que está ao vivo', () {
      expect(feed.featured.first.id, 'cromo-liga-prata-fria');
      expect(feed.featured.every((d) => d.featured), isTrue);
    });

    test('interesses do perfil sobem para o começo dos destaques', () {
      final liked = Feed.from(drops, now, interests: {'apparel'});
      expect(liked.featured.first.category, DropCategory.apparel);
      expect(liked.featured.length, feed.featured.length);
    });

    test('agrupa os próximos por dia', () {
      final groups = feed.upcomingByDay;
      expect(
        groups.fold<int>(0, (a, g) => a + g.drops.length),
        feed.upcoming.length,
      );
      for (final g in groups) {
        for (final d in g.drops) {
          expect(d.releaseAt!.day, g.day.day);
        }
      }
    });
  });

  group('Busca e filtros do Explore', () {
    ExploreResults run(ExploreFilter f) =>
        applyExploreFilter(drops: drops, brands: brands, filter: f, now: now);

    test('sem filtro devolve tudo, em ordem de radar', () {
      final r = run(const ExploreFilter());
      expect(r.drops.length, drops.length);
      expect(r.drops.first.statusAt(now), DropStatus.live);
      expect(r.drops.last.statusAt(now), DropStatus.released);
      expect(r.brands, isEmpty);
    });

    test('busca por nome de produto', () {
      final r = run(const ExploreFilter(query: 'arco'));
      expect(r.drops.map((d) => d.id), ['vertice-arco-01', 'vertice-arco-02']);
    });

    test('busca ignora acentos e maiúsculas', () {
      final r = run(const ExploreFilter(query: 'VERTICE'));
      expect(r.brands.map((b) => b.id), ['vertice']);
      expect(r.drops.length, 3);
      expect(r.drops.every((d) => d.brandId == 'vertice'), isTrue);
    });

    test('busca com várias palavras exige todas', () {
      final r = run(const ExploreFilter(query: 'cromo boné'));
      expect(r.drops.map((d) => d.id), ['cromo-bone-aro']);
    });

    test('filtro por categoria', () {
      final r = run(const ExploreFilter(category: DropCategory.accessories));
      expect(r.drops.length, 3);
      expect(
        r.drops.every((d) => d.category == DropCategory.accessories),
        isTrue,
      );
    });

    test('filtro por marca e status combinados', () {
      final r = run(
        const ExploreFilter(
          brandIds: {'kalt'},
          statuses: {DropStatus.released},
        ),
      );
      expect(r.drops.map((d) => d.id), ['kalt-neblina']);
    });

    test('ordenar por menor preço deixa "sem preço" no fim', () {
      final r = run(const ExploreFilter(sort: DropSort.priceLow));
      expect(r.drops.first.price, 189);
      final firstNull = r.drops.indexWhere((d) => d.price == null);
      expect(r.drops.skip(firstNull).every((d) => d.price == null), isTrue);
    });

    test('nada encontrado', () {
      expect(run(const ExploreFilter(query: 'zzzz')).isEmpty, isTrue);
    });

    test('conta os filtros ativos da folha', () {
      const f = ExploreFilter(
        brandIds: {'a', 'b'},
        statuses: {DropStatus.live},
        sort: DropSort.newest,
      );
      expect(f.sheetCount, 4);
      expect(f.isSearching, isTrue);
      expect(const ExploreFilter().isSearching, isFalse);
    });
  });

  group('Central de atividades', () {
    test('sem nada salvo, não há avisos', () {
      expect(
        buildActivity(drops: drops, user: const UserData(), now: now),
        isEmpty,
      );
    });

    test('drop salvo que está ao vivo gera aviso', () {
      final items = buildActivity(
        drops: drops,
        user: const UserData(wantList: {'cromo-liga-prata-fria'}),
        now: now,
      );
      expect(items.single.kind, ActivityKind.live);
      expect(items.single.read, isFalse);
      expect(items.single.dropId, 'cromo-liga-prata-fria');
    });

    test('drop salvo que abre em até 72 h gera aviso; mais longe, não', () {
      final items = buildActivity(
        drops: drops,
        user: const UserData(wantList: {'vertice-arco-01', 'vertice-arco-02'}),
        now: now,
      );
      expect(items.map((i) => i.dropId), ['vertice-arco-01']);
      expect(items.single.kind, ActivityKind.soon);
    });

    test('marca acompanhada avisa dos drops novos ainda não lançados', () {
      final items = buildActivity(
        drops: drops,
        user: const UserData(following: {'vertice'}),
        now: now,
      );
      expect(items.every((i) => i.kind == ActivityKind.brandDrop), isTrue);
      expect(items.map((i) => i.dropId).toSet(), {
        'vertice-arco-01',
        'vertice-arco-02',
        'vertice-viga-high',
      });
    });

    test('preferência desligada silencia o tipo de aviso', () {
      final items = buildActivity(
        drops: drops,
        user: UserData(
          wantList: const {'cromo-liga-prata-fria'},
          notifOff: {NotifPref.liveNow.name},
        ),
        now: now,
      );
      expect(items, isEmpty);
    });

    test('avisos marcados como lidos continuam na lista, como lidos', () {
      final first = buildActivity(
        drops: drops,
        user: const UserData(wantList: {'cromo-liga-prata-fria'}),
        now: now,
      );
      final again = buildActivity(
        drops: drops,
        user: UserData(
          wantList: const {'cromo-liga-prata-fria'},
          readActivity: {first.single.id},
        ),
        now: now,
      );
      expect(again.single.read, isTrue);
    });
  });

  group('Redirecionamento', () {
    String? go(
      String location, {
      bool splashDone = true,
      bool authLoading = false,
      bool loggedIn = false,
      bool onboarded = true,
    }) => resolveRedirect(
      location: location,
      splashDone: splashDone,
      authLoading: authLoading,
      loggedIn: loggedIn,
      onboarded: onboarded,
    );

    test('enquanto abre, tudo espera na abertura', () {
      expect(go('/discover', splashDone: false), '/splash');
      expect(go('/splash', splashDone: false), isNull);
      expect(go('/discover', authLoading: true), '/splash');
    });

    test('primeira vez vai para o onboarding', () {
      expect(go('/splash', onboarded: false), '/onboarding');
      expect(go('/onboarding', onboarded: false), isNull);
    });

    test('deslogado vai para o login e não entra em telas internas', () {
      expect(go('/splash'), '/login');
      expect(go('/want-list'), '/login');
      expect(go('/drop/abc'), '/login');
      expect(go('/signup'), isNull);
      expect(go('/forgot'), isNull);
    });

    test('logado sai das telas de entrada e fica nas internas', () {
      expect(go('/login', loggedIn: true), '/discover');
      expect(go('/splash', loggedIn: true), '/discover');
      expect(go('/onboarding', loggedIn: true), '/discover');
      expect(go('/drop/abc', loggedIn: true), isNull);
      expect(go('/settings', loggedIn: true), isNull);
    });
  });
}
