import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Carregando: três pontos em sequência (eco da retícula da marca).
class DripLoader extends StatefulWidget {
  const DripLoader({super.key, this.color, this.dot = 6});

  final Color? color;
  final double dot;

  @override
  State<DripLoader> createState() => _DripLoaderState();
}

class _DripLoaderState extends State<DripLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.c.text;
    return Semantics(
      label: 'Carregando',
      child: SizedBox(
        width: widget.dot * 5,
        height: widget.dot * 2,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) =>
              CustomPaint(painter: _DotsPainter(color, _c.value, widget.dot)),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color, this.t, this.dot);
  final Color color;
  final double t;
  final double dot;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final phase = (t - i * 0.16) % 1.0;
      final wave = (math.sin(phase * 2 * math.pi) + 1) / 2;
      canvas.drawCircle(
        Offset(dot / 2 + i * dot * 2, size.height / 2),
        dot / 2,
        Paint()..color = color.withValues(alpha: 0.25 + 0.75 * wave),
      );
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.t != t || old.color != color;
}

/// Bloco de espera que ocupa o lugar do conteúdo enquanto ele carrega.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = Radii.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.c.surfaceHigh,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
