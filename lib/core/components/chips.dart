import 'package:material_ui/material_ui.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';
import 'drip_icon.dart';
import 'liquid_glass.dart';

/// Metadado técnico: caixa alta, fonte expandida.
class Label extends StatelessWidget {
  const Label(this.text, {super.key, this.color, this.large = false});

  final String text;
  final Color? color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (large ? DripType.labelL : DripType.label).copyWith(
        color: color ?? context.c.textMuted,
      ),
    );
  }
}

/// Chip de filtro/seleção.
class DripChip extends StatelessWidget {
  const DripChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.glyph,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final int? count;
  final DripGlyph? glyph;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = selected ? c.onAccent : c.text;
    return Pressable(
      onTap: onTap,
      haptic: true,
      selected: selected,
      semanticLabel: count == null ? label : '$label, $count',
      focusRadius: Radii.pill,
      child: Center(
        widthFactor: 1,
        // Chip de vidro; selecionado, a cor sólida cobre o vidro.
        child: LiquidGlassContainer(
          borderRadius: BorderRadius.circular(Radii.pill),
          blurSigma: 4,
          tint: c.surface.withValues(alpha: 0.7),
          child: AnimatedContainer(
            duration: Motion.base,
            curve: Motion.out,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: Space.x4),
            decoration: BoxDecoration(
              color: selected ? c.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(
                color: selected ? c.accent : c.line.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (glyph != null) ...[
                  DripIcon(glyph!, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: DripType.caption.copyWith(
                    color: fg,
                    fontVariations: const [FontVariation('wght', 600)],
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: DripType.label.copyWith(
                      color: fg.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Célula de dado no estilo ficha técnica: legenda pequena + valor.
class FactCell extends StatelessWidget {
  const FactCell({
    super.key,
    required this.caption,
    required this.value,
    this.color,
    this.align = CrossAxisAlignment.start,
  });

  final String caption;
  final String value;
  final Color? color;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption,
            maxLines: 1,
            style: DripType.footnote.copyWith(
              color: color?.withValues(alpha: 0.7) ?? c.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DripType.dataM.copyWith(color: color ?? c.text),
          ),
        ],
      ),
    );
  }
}

/// Linha fina de separação.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.color, this.indent = 0});

  final Color? color;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.8,
      margin: EdgeInsets.only(left: indent),
      color: color ?? context.c.line,
    );
  }
}
