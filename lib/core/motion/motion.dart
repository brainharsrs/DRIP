import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Mola criticamente amortecida: resposta rápida, sem quique.
final SpringDescription kPressSpring = SpringDescription.withDampingRatio(
  mass: 1,
  stiffness: 520,
  ratio: 1,
);

/// Mola com leve quique, para confirmações (salvar, seguir).
final SpringDescription kPopSpring = SpringDescription.withDampingRatio(
  mass: 1,
  stiffness: 380,
  ratio: 0.62,
);

/// Anima a mudança de tamanho do filho; com "reduzir movimento" ligado, o
/// tamanho novo entra de uma vez.
///
/// Não usar `AnimatedSize` com duração zero: o controlador termina dentro do
/// próprio layout e o Flutter acusa erro.
class SoftSize extends StatelessWidget {
  const SoftSize({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return AnimatedSize(
      duration: Motion.base,
      curve: Motion.out,
      alignment: alignment,
      child: child,
    );
  }
}

/// Envolve qualquer conteúdo tocável.
///
/// Responde no *toque* (não na soltura) encolhendo levemente com mola, pode
/// ser interrompido a qualquer momento, garante área mínima de 44pt e mostra
/// um anel de foco para quem navega por teclado.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.scale = 0.965,
    this.haptic = false,
    this.minSize = 44,
    this.selected,
    this.disabledOpacity = 0.4,
    this.focusRadius = Radii.md,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;
  final double scale;
  final bool haptic;
  final double minSize;
  final bool? selected;
  final double disabledOpacity;
  final double focusRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: 0,
  );
  bool _focused = false;

  void _to(double target) {
    if (!mounted) return;
    _c.animateWith(SpringSimulation(kPressSpring, _c.value, target, 0));
  }

  void _activate() {
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: enabled ? _activate : null,
      excludeSemantics: widget.semanticLabel != null,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _to(1) : null,
          onTapCancel: enabled ? () => _to(0) : null,
          onTapUp: enabled ? (_) => _to(0) : null,
          onTap: enabled ? _activate : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: widget.minSize,
              minHeight: widget.minSize,
            ),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.focusRadius),
                border: _focused
                    ? Border.all(color: context.c.silver, width: 2)
                    : null,
              ),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  final t = _c.value.clamp(-0.2, 1.2);
                  return Transform.scale(
                    scale: 1 - (1 - widget.scale) * t,
                    child: child,
                  );
                },
                child: Opacity(
                  opacity: enabled ? 1 : widget.disabledOpacity,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Entrada de conteúdo: sobe alguns pontos enquanto aparece.
///
/// [index] escalona a entrada em listas. Com "reduzir movimento" ligado,
/// vira apenas um fade curto.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 18,
    this.delay = Duration.zero,
  });

  final Widget child;
  final int index;
  final double offset;
  final Duration delay;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final Duration _wait =
      widget.delay + Motion.stagger * widget.index.clamp(0, 8);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _wait + Motion.slow,
  )..forward();

  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _wait.inMilliseconds / (_wait + Motion.slow).inMilliseconds,
      1,
      curve: Motion.out,
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value.clamp(0, 1),
        child: reduce
            ? child
            : Transform.translate(
                offset: Offset(0, (1 - _t.value) * widget.offset),
                child: child,
              ),
      ),
      child: widget.child,
    );
  }
}

/// Revelação por máscara: o conteúdo sobe de trás de uma "linha" invisível.
/// É a assinatura dos títulos do DRIP.
class MaskReveal extends StatefulWidget {
  const MaskReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.reveal,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<MaskReveal> createState() => _MaskRevealState();
}

class _MaskRevealState extends State<MaskReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  )..forward();

  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMilliseconds /
          (widget.delay + widget.duration).inMilliseconds,
      1,
      curve: Motion.out,
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) {
      return FadeTransition(opacity: _t, child: widget.child);
    }
    return ClipRect(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) => FractionalTranslation(
          translation: Offset(0, 1.05 * (1 - _t.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Faixa que desliza continuamente (letreiro).
/// Fica parada quando o sistema pede menos movimento.
class Marquee extends StatefulWidget {
  const Marquee({
    super.key,
    required this.child,
    this.pixelsPerSecond = 36,
    this.reverse = false,
  });

  /// Um "bloco" da faixa; é repetido para preencher a largura.
  final Widget child;
  final double pixelsPerSecond;
  final bool reverse;

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  late final AnimationController _c = AnimationController(vsync: this);
  double _w = 0;

  void _measure() {
    if (!mounted) return;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final w = box.size.width;
    if (w <= 0 || (w - _w).abs() < 0.5) return;
    _w = w;
    _c.duration = Duration(
      milliseconds: (w / widget.pixelsPerSecond * 1000).round(),
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else {
      _c.repeat();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final screen = MediaQuery.sizeOf(context).width;
    final copies = _w == 0 ? 1 : (screen / _w).ceil() + 1;
    return ExcludeSemantics(
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          maxWidth: double.infinity,
          fit: OverflowBoxFit.deferToChild,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final t = widget.reverse ? 1 - _c.value : _c.value;
              return Transform.translate(
                offset: Offset(-t * _w, 0),
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                KeyedSubtree(key: _key, child: widget.child),
                for (var i = 1; i < copies; i++) widget.child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ponto que pulsa devagar: sinaliza "ao vivo".
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size * 2.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _PulsePainter(widget.color, _c.value, widget.size),
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.color, this.t, this.size);
  final Color color;
  final double t;
  final double size;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    canvas.drawCircle(
      c,
      size / 2 + (size * 0.7) * t,
      Paint()..color = color.withValues(alpha: 0.45 * (1 - t)),
    );
    canvas.drawCircle(c, size / 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t || old.color != color;
}

/// Transição de página do DRIP: o novo conteúdo desliza e aparece;
/// o anterior recua levemente (profundidade).
CustomTransitionPage<T> dripPage<T>({
  required LocalKey key,
  required Widget child,
  bool fromBottom = false,
  bool fadeOnly = false,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: Motion.slow,
    reverseTransitionDuration: Motion.base,
    transitionsBuilder: (context, animation, secondary, child) {
      final reduce = MediaQuery.disableAnimationsOf(context);
      final under = CurvedAnimation(parent: secondary, curve: Motion.out);
      final receded = reduce
          ? child
          : AnimatedBuilder(
              animation: under,
              builder: (context, inner) =>
                  Transform.scale(scale: 1 - 0.035 * under.value, child: inner),
              child: child,
            );
      final fade = FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.55),
        ),
        child: receded,
      );
      if (reduce || fadeOnly) return fade;
      final enter = CurvedAnimation(
        parent: animation,
        curve: Motion.out,
        reverseCurve: Motion.exit,
      );
      return SlideTransition(
        position: Tween(
          begin: fromBottom ? const Offset(0, 0.1) : const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(enter),
        child: fade,
      );
    },
  );
}
