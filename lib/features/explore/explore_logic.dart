import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/brand.dart';
import '../../data/models/drop.dart';
import '../../data/providers.dart';

enum DropSort {
  radar('Mais próximos'),
  newest('Adicionados por último'),
  priceLow('Menor preço');

  const DropSort(this.label);
  final String label;
}

/// Tudo o que a pessoa escolheu no Explore: texto, categoria, filtros, ordem.
class ExploreFilter {
  const ExploreFilter({
    this.query = '',
    this.category,
    this.brandIds = const {},
    this.statuses = const {},
    this.sort = DropSort.radar,
  });

  final String query;
  final DropCategory? category;
  final Set<String> brandIds;
  final Set<DropStatus> statuses;
  final DropSort sort;

  /// Quantos filtros da folha estão ligados (marca, status, ordem).
  int get sheetCount =>
      brandIds.length + statuses.length + (sort == DropSort.radar ? 0 : 1);

  /// `true` quando há busca ou filtro: a tela mostra resultados.
  bool get isSearching =>
      query.trim().isNotEmpty || category != null || sheetCount > 0;

  ExploreFilter copyWith({
    String? query,
    DropCategory? Function()? category,
    Set<String>? brandIds,
    Set<DropStatus>? statuses,
    DropSort? sort,
  }) => ExploreFilter(
    query: query ?? this.query,
    category: category == null ? this.category : category(),
    brandIds: brandIds ?? this.brandIds,
    statuses: statuses ?? this.statuses,
    sort: sort ?? this.sort,
  );
}

class ExploreResults {
  const ExploreResults({required this.brands, required this.drops});
  final List<Brand> brands;
  final List<Drop> drops;
  bool get isEmpty => brands.isEmpty && drops.isEmpty;
}

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
  'é': 'e', 'ê': 'e', 'è': 'e', 'ë': 'e',
  'í': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

/// Minúsculas e sem acentos: "Vértice" e "vertice" casam.
String foldText(String input) {
  final lower = input.toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    buf.write(_accents[ch] ?? ch);
  }
  return buf.toString();
}

/// Aplica busca, filtros e ordenação ao catálogo.
ExploreResults applyExploreFilter({
  required List<Drop> drops,
  required List<Brand> brands,
  required ExploreFilter filter,
  required DateTime now,
}) {
  final tokens = foldText(filter.query)
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  bool matches(String haystack) {
    final text = foldText(haystack);
    return tokens.every(text.contains);
  }

  final outDrops = drops.where((d) {
    if (filter.category != null && d.category != filter.category) return false;
    if (filter.brandIds.isNotEmpty && !filter.brandIds.contains(d.brandId)) {
      return false;
    }
    if (filter.statuses.isNotEmpty &&
        !filter.statuses.contains(d.statusAt(now))) {
      return false;
    }
    return tokens.isEmpty || matches(d.searchText);
  }).toList();

  switch (filter.sort) {
    case DropSort.radar:
      outDrops.sort((a, b) => compareByRadar(a, b, now));
    case DropSort.newest:
      outDrops.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case DropSort.priceLow:
      // Sem preço informado vai para o fim.
      outDrops.sort((a, b) {
        final pa = a.price, pb = b.price;
        if (pa == null && pb == null) return compareByRadar(a, b, now);
        if (pa == null) return 1;
        if (pb == null) return -1;
        return pa.compareTo(pb);
      });
  }

  // Marcas só entram no resultado quando há texto de busca.
  final outBrands = tokens.isEmpty
      ? <Brand>[]
      : brands.where((b) => matches('${b.name} ${b.tagline}')).toList();

  return ExploreResults(brands: outBrands, drops: outDrops);
}

class ExploreFilterNotifier extends Notifier<ExploreFilter> {
  @override
  ExploreFilter build() => const ExploreFilter();

  void setQuery(String q) => state = state.copyWith(query: q);

  void setCategory(DropCategory? c) =>
      state = state.copyWith(category: () => c);

  void apply({
    required Set<String> brandIds,
    required Set<DropStatus> statuses,
    required DropSort sort,
  }) => state = state.copyWith(
    brandIds: brandIds,
    statuses: statuses,
    sort: sort,
  );

  void clear() => state = const ExploreFilter();
}

final exploreFilterProvider =
    NotifierProvider<ExploreFilterNotifier, ExploreFilter>(
      ExploreFilterNotifier.new,
    );

final exploreResultsProvider = Provider<ExploreResults>((ref) {
  return applyExploreFilter(
    drops: ref.watch(dropsProvider).value ?? const [],
    brands: ref.watch(brandsProvider).value ?? const [],
    filter: ref.watch(exploreFilterProvider),
    now: ref.watch(nowProvider),
  );
});
