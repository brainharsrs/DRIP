import 'package:material_ui/material_ui.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';
import 'drip_icon.dart';
import 'liquid_glass.dart';
import 'loading.dart';

enum DripButtonKind { primary, secondary, ghost }

/// Botão em pílula do DRIP.
///
/// - `primary`: ação principal da tela (uma por tela).
/// - `secondary`: contorno, para ações de apoio.
/// - `ghost`: só texto, para ações discretas.
class DripButton extends StatelessWidget {
  const DripButton({
    super.key,
    required this.label,
    required this.onTap,
    this.kind = DripButtonKind.primary,
    this.loading = false,
    this.leading,
    this.trailing,
    this.expand = true,
    this.compact = false,
    this.foreground,
    this.background,
    this.semanticLabel,
  });

  /// Nome lido pelo leitor de tela quando o rótulo sozinho é ambíguo.
  final String? semanticLabel;
  final String label;
  final VoidCallback? onTap;
  final DripButtonKind kind;
  final bool loading;
  final DripGlyph? leading;
  final DripGlyph? trailing;
  final bool expand;
  final bool compact;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (Color bg, Color fg, Color? border) = switch (kind) {
      DripButtonKind.primary => (
        background ?? c.accent,
        foreground ?? c.onAccent,
        null,
      ),
      DripButtonKind.secondary => (
        background ?? Colors.transparent,
        foreground ?? c.text,
        (foreground ?? c.text).withValues(alpha: 0.28),
      ),
      DripButtonKind.ghost => (
        Colors.transparent,
        foreground ?? c.textMuted,
        null,
      ),
    };

    final content = Row(
      key: const ValueKey('content'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          DripIcon(leading!, size: 19, color: fg),
          const SizedBox(width: Space.x2),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DripType.button.copyWith(color: fg),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: Space.x2),
          DripIcon(trailing!, size: 19, color: fg),
        ],
      ],
    );

    return Pressable(
      onTap: loading ? null : onTap,
      disabledOpacity: loading ? 1 : 0.4,
      semanticLabel: loading
          ? '${semanticLabel ?? label}, carregando'
          : (semanticLabel ?? label),
      focusRadius: Radii.pill,
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.out,
        height: compact ? 44 : 56,
        width: expand ? double.infinity : null,
        alignment: expand ? Alignment.center : null,
        padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: border == null ? null : Border.all(color: border),
        ),
        child: AnimatedSwitcher(
          duration: Motion.base,
          child: loading
              ? DripLoader(key: const ValueKey('loading'), color: fg)
              : content,
        ),
      ),
    );
  }
}

/// Botão circular só com ícone. Sempre recebe um nome acessível.
class IconPill extends StatelessWidget {
  const IconPill({
    super.key,
    required this.glyph,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.color,
    this.background,
    this.glass = false,
    this.bordered = false,
  });

  final DripGlyph glyph;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final Color? background;

  /// Fundo translúcido com desfoque (para usar sobre imagens).
  final bool glass;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget body = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: glass
          ? null
          : BoxDecoration(
              shape: BoxShape.circle,
              color: background ?? Colors.transparent,
              border: bordered
                  ? Border.all(color: c.line.withValues(alpha: 0.8), width: 0.8)
                  : null,
            ),
      child: DripIcon(glyph, size: size * 0.48, color: color ?? c.text),
    );
    if (glass) {
      // Gota de vidro líquido sobre a imagem.
      body = LiquidGlassContainer(
        borderRadius: BorderRadius.circular(size / 2),
        blurSigma: 6,
        bendIntensity: 1.3,
        tint: background ?? c.glass,
        tintStrength: 0.6,
        child: body,
      );
    }
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      focusRadius: Radii.pill,
      scale: 0.9,
      child: body,
    );
  }
}
