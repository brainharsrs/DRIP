import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/components/drop_visual.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/drop.dart';
import '../../../data/providers.dart';
import '../../want_list/widgets/save_button.dart';
import 'drop_text.dart';

/// Abre os detalhes de um drop levando junto a etiqueta do Hero,
/// para a imagem "voar" da lista até a tela de detalhe.
void openDrop(BuildContext context, Drop drop, String heroTag) =>
    context.push(Routes.drop(drop.id), extra: heroTag);

/// Quadro com a imagem do drop sobre o fundo de estúdio.
class DropArtTile extends StatelessWidget {
  const DropArtTile({
    super.key,
    required this.drop,
    this.heroTag,
    this.radius = Radii.md,
    this.padding = const EdgeInsets.all(10),
  });

  final Drop drop;
  final String? heroTag;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final visual = DropVisual(drop: drop);
    return StudioBackdrop(
      tone: drop.tone,
      radius: radius,
      child: Padding(
        padding: padding,
        child: heroTag == null ? visual : Hero(tag: heroTag!, child: visual),
      ),
    );
  }
}

/// Linha "quando": com ponto pulsante se o drop está ao vivo.
class WhenLine extends ConsumerWidget {
  const WhenLine({super.key, required this.drop, this.timeOnly = false});

  final Drop drop;

  /// Mostra só o horário (para listas já agrupadas por dia).
  final bool timeOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final now = ref.watch(nowProvider);
    final live = drop.statusAt(now) == DropStatus.live;
    final text = timeOnly && !live ? drop.timeLine : drop.whenLine(now);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (live) ...[
          PulseDot(color: c.live, size: 6),
          const SizedBox(width: 2),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DripType.data.copyWith(
              fontSize: 13,
              color: live ? c.live : c.textFaint,
            ),
          ),
        ),
      ],
    );
  }
}

/// Um drop em linha: imagem, nome, marca, quando e o botão de salvar.
class DropRow extends ConsumerWidget {
  const DropRow({
    super.key,
    required this.drop,
    required this.slot,
    this.timeOnly = false,
    this.padding = const EdgeInsets.fromLTRB(Space.gutter, 6, Space.x2, 6),
  });

  final Drop drop;

  /// Nome do lugar onde a linha aparece (deixa a etiqueta do Hero única).
  final String slot;
  final bool timeOnly;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final tag = '$slot-${drop.id}';
    final now = ref.watch(nowProvider);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: () => openDrop(context, drop, tag),
              scale: 0.985,
              semanticLabel: drop.spoken(now),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: DropArtTile(
                      drop: drop,
                      heroTag: tag,
                      radius: Radii.sm + 2,
                      padding: const EdgeInsets.all(7),
                    ),
                  ),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          drop.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DripType.subhead.copyWith(color: c.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${drop.brandName} · ${drop.category.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DripType.caption.copyWith(color: c.textMuted),
                        ),
                        const SizedBox(height: 5),
                        WhenLine(drop: drop, timeOnly: timeOnly),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SaveButton(drop: drop),
        ],
      ),
    );
  }
}

/// Medidas do cartão de drop, compartilhadas por grades e filas.
abstract final class DropCardMetrics {
  static const artRatio = 0.92;

  /// Altura do bloco de texto abaixo da imagem, já com o tamanho de fonte
  /// escolhido pela pessoa.
  static double textHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(64) + 14;

  static double heightFor(BuildContext context, double width) =>
      width / artRatio + textHeight(context);
}

/// Fila horizontal de cartões de drop.
class DropCardStrip extends StatelessWidget {
  const DropCardStrip({super.key, required this.drops, required this.slot});

  final List<Drop> drops;
  final String slot;

  static const _cardWidth = 150.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DropCardMetrics.heightFor(context, _cardWidth),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
        itemCount: drops.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.x3),
        itemBuilder: (_, i) => SizedBox(
          width: _cardWidth,
          child: DropCard(drop: drops[i], slot: slot),
        ),
      ),
    );
  }
}

/// Grade de cartões de drop, para usar dentro de um `CustomScrollView`.
class DropSliverGrid extends StatelessWidget {
  const DropSliverGrid({super.key, required this.drops, required this.slot});

  final List<Drop> drops;
  final String slot;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 840 ? 4 : (width >= 560 ? 3 : 2);
    const gap = Space.x3;
    final cardWidth =
        (width - Space.gutter * 2 - gap * (columns - 1)) / columns;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      sliver: SliverGrid.builder(
        itemCount: drops.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: gap,
          mainAxisSpacing: Space.x5,
          mainAxisExtent: DropCardMetrics.heightFor(context, cardWidth),
        ),
        itemBuilder: (_, i) => DropCard(drop: drops[i], slot: slot),
      ),
    );
  }
}

/// Um drop em cartão vertical (grades e listas horizontais).
class DropCard extends ConsumerWidget {
  const DropCard({super.key, required this.drop, required this.slot});

  final Drop drop;
  final String slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final tag = '$slot-${drop.id}';
    final now = ref.watch(nowProvider);
    return Stack(
      children: [
        Pressable(
          onTap: () => openDrop(context, drop, tag),
          scale: 0.975,
          semanticLabel: drop.spoken(now),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: DropCardMetrics.artRatio,
                child: DropArtTile(
                  drop: drop,
                  heroTag: tag,
                  padding: const EdgeInsets.fromLTRB(14, 26, 14, 14),
                ),
              ),
              const SizedBox(height: Space.x2 + 2),
              Text(
                drop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DripType.subhead.copyWith(fontSize: 15, color: c.text),
              ),
              const SizedBox(height: 1),
              Text(
                drop.brandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DripType.caption.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: 4),
              WhenLine(drop: drop),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: SaveButton(drop: drop, ink: StudioBackdrop.inkOn(drop.tone)),
        ),
      ],
    );
  }
}
