import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/drop.dart';
import '../../data/providers.dart';

/// O feed do Discover, já separado por momento.
class Feed {
  const Feed({
    required this.featured,
    required this.live,
    required this.upcoming,
    required this.released,
    required this.tbd,
  });

  /// Destaques do topo (ao vivo ou prestes a abrir).
  final List<Drop> featured;

  /// Abertos agora.
  final List<Drop> live;

  /// Com data marcada, do mais próximo ao mais distante.
  final List<Drop> upcoming;

  /// Já lançados, do mais recente ao mais antigo.
  final List<Drop> released;

  /// Anunciados, ainda sem data.
  final List<Drop> tbd;

  bool get isEmpty =>
      live.isEmpty && upcoming.isEmpty && released.isEmpty && tbd.isEmpty;

  /// [interests] são nomes de categoria escolhidos no Perfil: drops dessas
  /// categorias sobem para o começo dos destaques.
  factory Feed.from(
    List<Drop> drops,
    DateTime now, {
    Set<String> interests = const {},
  }) {
    final live = <Drop>[];
    final upcoming = <Drop>[];
    final released = <Drop>[];
    final tbd = <Drop>[];
    for (final d in drops) {
      switch (d.statusAt(now)) {
        case DropStatus.live:
          live.add(d);
        case DropStatus.upcoming:
          upcoming.add(d);
        case DropStatus.released:
          released.add(d);
        case DropStatus.tbd:
          tbd.add(d);
      }
    }
    upcoming.sort((a, b) => a.releaseAt!.compareTo(b.releaseAt!));
    live.sort((a, b) => b.releaseAt!.compareTo(a.releaseAt!));
    released.sort((a, b) => b.releaseAt!.compareTo(a.releaseAt!));
    tbd.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    var featured = [
      ...live.where((d) => d.featured),
      ...upcoming.where((d) => d.featured),
    ];
    // Sem destaque marcado pela equipe: usa o que está mais perto de abrir.
    if (featured.isEmpty) featured = [...live, ...upcoming];
    if (interests.isNotEmpty) {
      bool liked(Drop d) => interests.contains(d.category.name);
      featured = [
        ...featured.where(liked),
        ...featured.where((d) => !liked(d)),
      ];
    }
    return Feed(
      featured: featured.take(5).toList(),
      live: live,
      upcoming: upcoming,
      released: released,
      tbd: tbd,
    );
  }

  /// Próximos drops agrupados por dia, em ordem.
  List<({DateTime day, List<Drop> drops})> get upcomingByDay {
    final groups = <({DateTime day, List<Drop> drops})>[];
    for (final d in upcoming) {
      final at = d.releaseAt!;
      final day = DateTime(at.year, at.month, at.day);
      if (groups.isNotEmpty && groups.last.day == day) {
        groups.last.drops.add(d);
      } else {
        groups.add((day: day, drops: [d]));
      }
    }
    return groups;
  }
}

final feedProvider = Provider<AsyncValue<Feed>>((ref) {
  final now = ref.watch(nowProvider);
  final interests = ref.watch(userDataProvider.select((d) => d.interests));
  return ref
      .watch(dropsProvider)
      .whenData((drops) => Feed.from(drops, now, interests: interests));
});
