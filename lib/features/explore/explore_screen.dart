import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/components/buttons.dart';
import '../../core/components/chips.dart';
import '../../core/components/drip_icon.dart';
import '../../core/components/fields.dart';
import '../../core/components/loading.dart';
import '../../core/components/states.dart';
import '../../core/components/surfaces.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/brand.dart';
import '../../data/models/drop.dart';
import '../../data/providers.dart';
import '../brands/widgets/brand_widgets.dart';
import '../drops/widgets/drop_tiles.dart';
import '../shell/tab_page.dart';
import 'explore_logic.dart';

/// Explore: busca de verdade + filtros por categoria, marca e status.
/// Sem busca ativa, mostra as marcas e o catálogo inteiro para navegar.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearAll() {
    _search.clear();
    ref.read(exploreFilterProvider.notifier).clear();
  }

  Future<void> _openFilters(List<Brand> brands) async {
    FocusScope.of(context).unfocus();
    await showDripSheet<void>(
      context: context,
      title: 'Filtros',
      builder: (_) => _FilterSheet(brands: brands),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final filter = ref.watch(exploreFilterProvider);
    final results = ref.watch(exploreResultsProvider);
    final dropsAsync = ref.watch(dropsProvider);
    final brands = ref.watch(brandsProvider).value ?? const <Brand>[];
    final notifier = ref.read(exploreFilterProvider.notifier);
    final scaler = MediaQuery.textScalerOf(context);
    final fieldH = 30 + scaler.scale(26);

    final pinned = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: SizedBox(
            height: fieldH,
            child: SearchField(
              controller: _search,
              hint: 'Buscar marcas e lançamentos',
              onChanged: notifier.setQuery,
            ),
          ),
        ),
        const SizedBox(height: Space.x2),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            children: [
              DripChip(
                label: 'Tudo',
                selected: filter.category == null,
                onTap: () => notifier.setCategory(null),
              ),
              for (final cat in DropCategory.values) ...[
                const SizedBox(width: Space.x2),
                DripChip(
                  label: cat.label,
                  selected: filter.category == cat,
                  onTap: () =>
                      notifier.setCategory(filter.category == cat ? null : cat),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final List<Widget> slivers;
    if (dropsAsync.isLoading && !dropsAsync.hasValue) {
      slivers = [const SliverToBoxAdapter(child: _Loading())];
    } else if (dropsAsync.hasError && !dropsAsync.hasValue) {
      slivers = [
        SliverToBoxAdapter(
          child: ErrorState(
            message:
                'Não conseguimos buscar o catálogo. Confira sua conexão e '
                'tente de novo.',
            onRetry: () => ref.invalidate(dropsProvider),
          ),
        ),
      ];
    } else if (filter.isSearching) {
      final total = results.brands.length + results.drops.length;
      slivers = [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.x2,
              Space.x2,
              Space.x2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(switch (total) {
                      0 => 'Nenhum resultado',
                      1 => '1 resultado',
                      _ => '$total resultados',
                    }, style: DripType.caption.copyWith(color: c.textMuted)),
                  ),
                ),
                DripButton(
                  label: 'Limpar',
                  semanticLabel: 'Limpar busca e filtros',
                  kind: DripButtonKind.ghost,
                  expand: false,
                  compact: true,
                  onTap: _clearAll,
                ),
              ],
            ),
          ),
        ),
        if (results.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              glyph: DripGlyph.search,
              title: 'Nada encontrado',
              message: filter.query.trim().isEmpty
                  ? 'Nenhum lançamento combina com esses filtros. '
                        'Tire um deles para ver mais.'
                  : 'Não achamos nada para "${filter.query.trim()}". Tente o '
                        'nome de outra marca ou produto.',
              actionLabel: 'Limpar busca e filtros',
              onAction: _clearAll,
            ),
          ),
        if (results.brands.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionTitle('Marcas', count: results.brands.length),
          ),
          SliverList.builder(
            itemCount: results.brands.length,
            itemBuilder: (_, i) => BrandRow(brand: results.brands[i]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.x6)),
        ],
        if (results.drops.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionTitle('Lançamentos', count: results.drops.length),
          ),
          DropSliverGrid(drops: results.drops, slot: 'search'),
        ],
      ];
    } else {
      slivers = [
        const SliverToBoxAdapter(child: SizedBox(height: Space.x2)),
        if (brands.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionTitle('Marcas', count: brands.length),
          ),
          SliverList.builder(
            itemCount: brands.length,
            itemBuilder: (_, i) => BrandRow(brand: brands[i]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.x8)),
        ],
        if (results.drops.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              glyph: DripGlyph.radar,
              title: 'Catálogo vazio',
              message:
                  'Ainda não há lançamentos cadastrados. Volte em breve: '
                  'os drops aparecem aqui assim que forem publicados.',
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: SectionTitle(
              'Todos os lançamentos',
              count: results.drops.length,
            ),
          ),
          DropSliverGrid(drops: results.drops, slot: 'all'),
        ],
      ];
    }

    return TabPage(
      tabIndex: 1,
      title: 'Explorar',
      largeTitle: false,
      pinned: pinned,
      pinnedHeight: fieldH + Space.x2 + 46 + 6,
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconPill(
              glyph: DripGlyph.sliders,
              label: filter.sheetCount == 0
                  ? 'Filtros'
                  : 'Filtros, ${filter.sheetCount} ativos',
              onTap: () => _openFilters(brands),
            ),
            if (filter.sheetCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: IgnorePointer(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Text(
                      '${filter.sheetCount}',
                      style: DripType.tab.copyWith(color: c.onAccent),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
      slivers: slivers,
    );
  }
}

/// Folha de filtros: status, marcas e ordenação. Só aplica ao confirmar.
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.brands});
  final List<Brand> brands;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late Set<String> _brandIds;
  late Set<DropStatus> _statuses;
  late DropSort _sort;

  @override
  void initState() {
    super.initState();
    final f = ref.read(exploreFilterProvider);
    _brandIds = {...f.brandIds};
    _statuses = {...f.statuses};
    _sort = f.sort;
  }

  void _toggle<T>(Set<T> set, T value) =>
      setState(() => set.contains(value) ? set.remove(value) : set.add(value));

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final base = ref.watch(exploreFilterProvider);
    final count = applyExploreFilter(
      drops: ref.watch(dropsProvider).value ?? const [],
      brands: const [],
      filter: base.copyWith(
        brandIds: _brandIds,
        statuses: _statuses,
        sort: _sort,
      ),
      now: ref.watch(nowProvider),
    ).drops.length;

    Widget group(String title, List<Widget> chips) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: DripType.subhead.copyWith(color: c.text)),
        ),
        const SizedBox(height: Space.x2),
        Wrap(spacing: Space.x2, runSpacing: 2, children: chips),
        const SizedBox(height: Space.x5),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        group('Status', [
          for (final s in DropStatus.values)
            DripChip(
              label: s.label,
              selected: _statuses.contains(s),
              onTap: () => _toggle(_statuses, s),
            ),
        ]),
        if (widget.brands.isNotEmpty)
          group('Marcas', [
            for (final b in widget.brands)
              DripChip(
                label: b.name,
                selected: _brandIds.contains(b.id),
                onTap: () => _toggle(_brandIds, b.id),
              ),
          ]),
        group('Ordenar por', [
          for (final s in DropSort.values)
            DripChip(
              label: s.label,
              selected: _sort == s,
              onTap: () => setState(() => _sort = s),
            ),
        ]),
        Row(
          children: [
            DripButton(
              label: 'Limpar',
              semanticLabel: 'Limpar filtros',
              kind: DripButtonKind.secondary,
              expand: false,
              onTap: () => setState(() {
                _brandIds = {};
                _statuses = {};
                _sort = DropSort.radar;
              }),
            ),
            const SizedBox(width: Space.x3),
            Expanded(
              child: DripButton(
                label: switch (count) {
                  0 => 'Nenhum resultado',
                  1 => 'Ver 1 lançamento',
                  _ => 'Ver $count lançamentos',
                },
                onTap: () {
                  ref
                      .read(exploreFilterProvider.notifier)
                      .apply(
                        brandIds: _brandIds,
                        statuses: _statuses,
                        sort: _sort,
                      );
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando catálogo',
      child: Column(
        children: [
          for (var i = 0; i < 5; i++)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                Space.gutter,
                Space.x2,
                Space.gutter,
                Space.x3,
              ),
              child: Row(
                children: [
                  Skeleton(width: 52, height: 52, radius: 26),
                  SizedBox(width: Space.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(width: 140, height: 16),
                        SizedBox(height: 8),
                        Skeleton(width: 200, height: 13),
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
