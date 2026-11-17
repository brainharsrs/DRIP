import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/components/drip_icon.dart';
import '../../core/components/loading.dart';
import '../../core/components/states.dart';
import '../../core/components/surfaces.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/drop.dart';
import '../../data/providers.dart';
import '../discover/feed.dart';
import '../drops/widgets/drop_tiles.dart';
import '../shell/tab_page.dart';

/// Want List: os drops que a pessoa salvou, do mais urgente ao mais antigo.
/// Para remover: toque no marcador ou arraste a linha para a esquerda.
class WantListScreen extends ConsumerStatefulWidget {
  const WantListScreen({super.key});

  @override
  ConsumerState<WantListScreen> createState() => _WantListScreenState();
}

class _WantListScreenState extends ConsumerState<WantListScreen> {
  /// Itens arrastados para fora, escondidos na hora (antes de os dados
  /// confirmarem a remoção).
  final _hidden = <String>{};

  void _remove(Drop drop) {
    final actions = ref.read(userActionsProvider);
    setState(() => _hidden.add(drop.id));
    actions.setWant(drop.id, false);
    showToast(
      context,
      '${drop.name} saiu da Want List.',
      actionLabel: 'Desfazer',
      onAction: () {
        actions.setWant(drop.id, true);
        if (mounted) setState(() => _hidden.remove(drop.id));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final catalog = ref.watch(dropsProvider);
    final wanted = ref.watch(userDataProvider.select((d) => d.wantList));
    final now = ref.watch(nowProvider);

    // Um item removido e depois salvo de novo em outro lugar volta a aparecer.
    _hidden.removeWhere((id) => !wanted.contains(id));

    final saved =
        (catalog.value ?? const <Drop>[])
            .where((d) => wanted.contains(d.id) && !_hidden.contains(d.id))
            .toList()
          ..sort((a, b) => compareByRadar(a, b, now));

    List<Drop> of(DropStatus s) =>
        saved.where((d) => d.statusAt(now) == s).toList();

    final List<Widget> slivers;
    if (catalog.isLoading && !catalog.hasValue) {
      slivers = [const SliverToBoxAdapter(child: _Loading())];
    } else if (catalog.hasError && !catalog.hasValue) {
      slivers = [
        SliverToBoxAdapter(
          child: ErrorState(
            message:
                'Não conseguimos carregar seus drops salvos. Confira sua '
                'conexão e tente de novo.',
            onRetry: () => ref.invalidate(dropsProvider),
          ),
        ),
      ];
    } else if (saved.isEmpty) {
      final suggestions =
          ref.watch(feedProvider).value?.upcoming.take(3).toList() ??
          const <Drop>[];
      slivers = [
        SliverToBoxAdapter(
          child: EmptyState(
            glyph: DripGlyph.bookmark,
            title: 'Nada salvo ainda',
            message:
                'Toque no marcador de um drop para guardá-lo aqui. Você '
                'recebe um aviso em Atividade antes de ele abrir.',
            actionLabel: 'Explorar lançamentos',
            onAction: () => context.go(Routes.explore),
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              0,
              Space.gutter,
              Space.x8,
            ),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionTitle('Abrindo em breve')),
          SliverList.builder(
            itemCount: suggestions.length,
            itemBuilder: (_, i) =>
                DropRow(drop: suggestions[i], slot: 'suggest'),
          ),
        ],
      ];
    } else {
      Widget section(String title, List<Drop> drops) => SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: SectionTitle(title, count: drops.length)),
          SliverList.builder(
            itemCount: drops.length,
            itemBuilder: (_, i) {
              final drop = drops[i];
              return Dismissible(
                key: ValueKey('want-${drop.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _remove(drop),
                background: Container(
                  color: c.surface,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: Space.x6),
                  child: Text(
                    'Remover',
                    style: DripType.button.copyWith(color: c.text),
                  ),
                ),
                child: ColoredBox(
                  color: c.bg,
                  child: DropRow(drop: drop, slot: 'want'),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.x6)),
        ],
      );

      final live = of(DropStatus.live);
      final soon = of(DropStatus.upcoming);
      final tbd = of(DropStatus.tbd);
      final out = of(DropStatus.released);
      slivers = [
        if (live.isNotEmpty) section('Ao vivo agora', live),
        if (soon.isNotEmpty) section('Abrindo em breve', soon),
        if (tbd.isNotEmpty) section('Sem data ainda', tbd),
        if (out.isNotEmpty) section('Já lançados', out),
      ];
    }

    return TabPage(
      tabIndex: 2,
      title: 'Want List',
      count: saved.length,
      slivers: slivers,
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando sua Want List',
      child: Column(
        children: [
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                Space.gutter,
                Space.x2,
                Space.gutter,
                Space.x3,
              ),
              child: Row(
                children: [
                  Skeleton(width: 72, height: 72),
                  SizedBox(width: Space.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(width: 160, height: 18),
                        SizedBox(height: 8),
                        Skeleton(width: 110, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
