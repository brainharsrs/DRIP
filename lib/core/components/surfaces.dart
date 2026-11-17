import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';
import 'buttons.dart';
import 'drip_icon.dart';
import 'liquid_glass.dart';

export 'liquid_glass.dart' show LiquidGlassContainer;

enum GlassEdge { none, top, bottom, all }

/// Material translúcido para barras que flutuam sobre o conteúdo
/// (o conteúdo rola por baixo). Vira superfície sólida em alto contraste.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 0,
    this.edge = GlassEdge.none,
    this.tint,
  });

  final Widget child;
  final double radius;
  final GlassEdge edge;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final side = BorderSide(color: c.line.withValues(alpha: 0.7), width: 0.8);
    // Barras presas numa borda da tela: a forma do vidro passa da tela nos
    // outros lados, então só a borda voltada para o conteúdo curva a luz.
    const far = 80.0;
    final overflow = switch (edge) {
      GlassEdge.bottom => const EdgeInsets.fromLTRB(far, far, far, 0),
      GlassEdge.top => const EdgeInsets.fromLTRB(far, 0, far, far),
      _ => EdgeInsets.zero,
    };
    return LiquidGlassContainer(
      borderRadius: BorderRadius.circular(radius),
      blurSigma: 14,
      tint: tint ?? c.glass,
      tintStrength: 0.75,
      rim: edge == GlassEdge.all || edge == GlassEdge.none && radius > 0,
      shapeOverflow: overflow,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: switch (edge) {
            GlassEdge.none => null,
            GlassEdge.top => Border(top: side),
            GlassEdge.bottom => Border(bottom: side),
            GlassEdge.all => Border.fromBorderSide(side),
          },
          borderRadius: edge == GlassEdge.all
              ? BorderRadius.circular(radius)
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// Título de seção com contador sobrescrito e ação opcional à direita.
class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.count,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      Space.gutter,
      0,
      Space.x2,
      Space.x3,
    ),
  });

  final String title;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          // O título fica com todo o espaço que a ação não usa.
          Expanded(
            child: Semantics(
              header: true,
              label: count == null ? title : '$title, $count',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DripType.title.copyWith(color: c.text),
                    ),
                  ),
                  if (count != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 5, top: 1),
                      child: Text(
                        '$count',
                        style: DripType.label.copyWith(color: c.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (actionLabel != null)
            Pressable(
              onTap: onAction,
              semanticLabel: '$actionLabel: $title',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: DripType.caption.copyWith(
                        color: c.textMuted,
                        fontVariations: const [FontVariation('wght', 600)],
                      ),
                    ),
                    const SizedBox(width: 4),
                    DripIcon(
                      DripGlyph.arrowRight,
                      size: 15,
                      color: c.textMuted,
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 44, width: Space.x3),
        ],
      ),
    );
  }
}

/// Abre uma folha inferior para uma tarefa curta e independente
/// (filtros, editar nome). Pode ser dispensada arrastando para baixo.
Future<T?> showDripSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.c.scrim,
    elevation: 0,
    builder: (ctx) => _SheetFrame(title: title, child: builder(ctx)),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        // Folha de vidro: o conteúdo atrás aparece curvado na borda de cima.
        child: LiquidGlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          blurSigma: 18,
          tint: c.surface.withValues(alpha: 0.9),
          tintStrength: 0.85,
          shapeOverflow: const EdgeInsets.only(bottom: 80),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    decoration: BoxDecoration(
                      color: c.line,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.gutter, 4, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: DripType.headline.copyWith(color: c.text),
                          ),
                        ),
                      ),
                      IconPill(
                        glyph: DripGlyph.close,
                        label: 'Fechar',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      Space.x2,
                      Space.gutter,
                      Space.x5,
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

OverlayEntry? _toastEntry;

/// Aviso curto no topo da tela, com ação opcional (ex.: "Desfazer").
/// Some sozinho; também pode ser dispensado com um toque.
void showToast(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  if (_toastEntry?.mounted ?? false) _toastEntry!.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      onDone: () {
        if (_toastEntry == entry) _toastEntry = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _toastEntry = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.message,
    required this.onDone,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.slow,
    reverseDuration: Motion.base,
  )..forward();
  late final Timer _timer = Timer(
    Duration(milliseconds: widget.actionLabel == null ? 2800 : 4200),
    _dismiss,
  );
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _timer; // inicia a contagem
  }

  Future<void> _dismiss() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    _timer.cancel();
    await _c.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _timer.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final reduce = context.reduceMotion;
    final curved = CurvedAnimation(
      parent: _c,
      curve: Motion.out,
      reverseCurve: Motion.exit,
    );
    Widget body = Material(
      color: Colors.transparent,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: GestureDetector(
          onTap: _dismiss,
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) < 0) _dismiss();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.fromLTRB(Space.x4, 6, 6, 6),
            decoration: BoxDecoration(
              color: c.text,
              borderRadius: BorderRadius.circular(Radii.md),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      widget.message,
                      style: DripType.caption.copyWith(
                        color: c.bg,
                        fontVariations: const [FontVariation('wght', 560)],
                      ),
                    ),
                  ),
                ),
                if (widget.actionLabel != null)
                  Pressable(
                    onTap: () {
                      widget.onAction?.call();
                      _dismiss();
                    },
                    semanticLabel: widget.actionLabel,
                    child: Center(
                      widthFactor: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          widget.actionLabel!,
                          style: DripType.button.copyWith(color: c.bg),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: Space.x3),
              ],
            ),
          ),
        ),
      ),
    );

    body = FadeTransition(opacity: _c, child: body);
    if (!reduce) {
      body = SlideTransition(
        position: Tween(
          begin: const Offset(0, -1.3),
          end: Offset.zero,
        ).animate(curved),
        child: body,
      );
    }
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: Space.x4,
      right: Space.x4,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: body,
        ),
      ),
    );
  }
}
