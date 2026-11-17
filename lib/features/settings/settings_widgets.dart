import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/components/buttons.dart';
import '../../core/components/chips.dart';
import '../../core/components/drip_icon.dart';
import '../../core/components/surfaces.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';

/// Tela secundária simples: barra translúcida com "voltar" e título,
/// conteúdo rolando por baixo.
class SubPage extends StatelessWidget {
  const SubPage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  static const _barHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final insets = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              top: insets.top + _barHeight + Space.x4,
              bottom: insets.bottom + Space.x8,
            ),
            children: children,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: insets.top + _barHeight,
            child: Glass(
              edge: GlassEdge.bottom,
              child: Padding(
                padding: EdgeInsets.fromLTRB(Space.x2, insets.top, Space.x4, 0),
                child: Row(
                  children: [
                    IconPill(
                      glyph: DripGlyph.arrowLeft,
                      label: 'Voltar',
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go(Routes.discover),
                    ),
                    const SizedBox(width: Space.x1),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DripType.headline.copyWith(color: c.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grupo de linhas em um único quadro, no formato de lista de ajustes.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.children,
    this.title,
    this.footer,
  });

  final String? title;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.x6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: Space.x2),
              child: Semantics(
                header: true,
                child: Text(
                  title!,
                  style: DripType.subhead.copyWith(color: c.text),
                ),
              ),
            ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Hairline(indent: Space.x4),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, Space.x2, 4, 0),
              child: Text(
                footer!,
                style: DripType.footnote.copyWith(color: c.textFaint),
              ),
            ),
        ],
      ),
    );
  }
}

/// Linha de ajuste: título, detalhe opcional e valor ou seta à direita.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DripType.body.copyWith(
                    color: danger ? c.danger : c.text,
                    fontVariations: const [FontVariation('wght', 520)],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: DripType.caption.copyWith(color: c.textMuted),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: Space.x3),
            // Largura limitada (e não flexível): o valor encosta na direita
            // e o título fica com o resto da linha.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.5,
              ),
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: DripType.body.copyWith(color: c.textMuted),
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: Space.x2),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: Space.x2),
            DripIcon(DripGlyph.chevronRight, size: 16, color: c.textFaint),
          ],
        ],
      ),
    );
    final spoken = [title, ?subtitle, ?value].join('. ');
    if (onTap == null) {
      return Semantics(
        label: trailing == null ? spoken : null,
        excludeSemantics: trailing == null,
        child: content,
      );
    }
    return Pressable(
      onTap: onTap,
      scale: 0.99,
      semanticLabel: spoken,
      focusRadius: 0,
      child: content,
    );
  }
}

/// Linha com interruptor. A linha inteira alterna o valor.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      toggled: value,
      label: [title, ?subtitle].join('. '),
      onTap: () => onChanged(!value),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.x4, 10, Space.x3, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DripType.body.copyWith(
                        color: c.text,
                        fontVariations: const [FontVariation('wght', 520)],
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: DripType.caption.copyWith(color: c.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Space.x2),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// Controle segmentado: escolhe uma entre poucas opções.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final n = options.length;
    final index = options.indexWhere((o) => o.$1 == value).clamp(0, n - 1);
    return Container(
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: context.reduceMotion ? Duration.zero : Motion.base,
            curve: Motion.out,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Pressable(
                    onTap: () => onChanged(options[i].$1),
                    haptic: true,
                    selected: i == index,
                    semanticLabel: options[i].$2,
                    focusRadius: Radii.pill,
                    minSize: 40,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: Motion.base,
                        style: DripType.caption.copyWith(
                          color: i == index ? c.onAccent : c.text,
                          fontVariations: const [FontVariation('wght', 620)],
                        ),
                        child: Text(options[i].$2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pede confirmação numa folha inferior. Devolve `true` se a pessoa confirmou.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final result = await showDripSheet<bool>(
    context: context,
    title: title,
    builder: (ctx) {
      final c = ctx.c;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: DripType.body.copyWith(color: c.textMuted)),
          const SizedBox(height: Space.x5),
          DripButton(
            label: confirmLabel,
            background: danger ? c.danger : null,
            foreground: danger ? c.onAccent : null,
            onTap: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: Space.x1),
          DripButton(
            label: 'Cancelar',
            kind: DripButtonKind.ghost,
            foreground: c.text,
            onTap: () => Navigator.of(ctx).pop(false),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
