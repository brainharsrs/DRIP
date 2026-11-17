import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Selo circular: um texto corre pela borda e o centro guarda o dado
/// principal (ex.: a contagem regressiva de um drop).
///
/// O anel gira bem devagar; com "reduzir movimento", fica parado.
class CircularStamp extends StatefulWidget {
  const CircularStamp({
    super.key,
    required this.text,
    this.child,
    this.size = 176,
    this.color,
    this.fill,
    this.spin = true,
  });

  /// Cor de fundo do disco (para o selo ficar legível sobre imagens).
  final Color? fill;

  /// Texto do anel. É repetido até dar a volta.
  final String text;
  final Widget? child;
  final double size;
  final Color? color;
  final bool spin;

  @override
  State<CircularStamp> createState() => _CircularStampState();
}

class _CircularStampState extends State<CircularStamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 48),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.spin || context.reduceMotion) {
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
    final color = widget.color ?? context.c.text;
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _RingsPainter(color, widget.fill)),
            ),
          ),
          Positioned.fill(
            child: ExcludeSemantics(
              child: RotationTransition(
                turns: _c,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _RingTextPainter(widget.text, color),
                  ),
                ),
              ),
            ),
          ),
          if (widget.child != null)
            Padding(
              padding: EdgeInsets.all(widget.size * 0.2),
              child: Center(child: widget.child),
            ),
        ],
      ),
    );
  }
}

const _bandRatio = 0.15;

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.color, this.fill);
  final Color color;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;
    if (fill != null) canvas.drawCircle(center, r, Paint()..color = fill!);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = color;
    canvas.drawCircle(center, r - 0.6, p);
    canvas.drawCircle(center, r - size.width * _bandRatio, p);
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.color != color || old.fill != fill;
}

class _RingTextPainter extends CustomPainter {
  _RingTextPainter(this.text, this.color);
  final String text;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final band = size.width * _bandRatio;
    final rt = r - band / 2;
    final fontSize = size.width * 0.05;
    final style = DripType.label.copyWith(
      fontSize: fontSize,
      letterSpacing: 0,
      height: 1,
      color: color,
    );

    final glyphs = [
      for (final rune in text.toUpperCase().runes)
        TextPainter(
          text: TextSpan(text: String.fromCharCode(rune), style: style),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    // Entre uma repetição e outra vai um pequeno diamante, desenhado como
    // forma (não depende de a fonte ter o caractere).
    final diamond = fontSize * 0.5;
    final separator = diamond + fontSize * 2.2;
    final unitWidth = glyphs.fold<double>(0, (a, g) => a + g.width) + separator;
    final circumference = 2 * math.pi * rt;
    final repeats = math.max(1, (circumference / (unitWidth * 1.08)).floor());
    final extra =
        (circumference - repeats * unitWidth) / (repeats * (glyphs.length + 1));
    final ink = Paint()..color = color;

    canvas.translate(r, r);
    var angle = -math.pi / 2;
    for (var n = 0; n < repeats; n++) {
      for (final g in glyphs) {
        final advance = (g.width + extra) / rt;
        canvas.save();
        canvas.rotate(angle + advance / 2 + math.pi / 2);
        g.paint(canvas, Offset(-g.width / 2, -rt - g.height / 2));
        canvas.restore();
        angle += advance;
      }
      final advance = (separator + extra) / rt;
      canvas.save();
      canvas.rotate(angle + advance / 2 + math.pi / 2);
      canvas.translate(0, -rt);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: diamond, height: diamond),
        ink,
      );
      canvas.restore();
      angle += advance;
    }
    for (final g in glyphs) {
      g.dispose();
    }
  }

  @override
  bool shouldRepaint(_RingTextPainter old) =>
      old.text != text || old.color != color;
}

/// Anel de órbita: uma elipse fina com um ponto que dá a volta devagar.
/// É o "radar" em torno do produto. Parado com "reduzir movimento".
class OrbitRing extends StatefulWidget {
  const OrbitRing({super.key, required this.color, this.tilt = -0.18});

  final Color color;
  final double tilt;

  @override
  State<OrbitRing> createState() => _OrbitRingState();
}

class _OrbitRingState extends State<OrbitRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.value = 0.12;
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
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _OrbitPainter(widget.color, _c.value, widget.tilt),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.color, this.t, this.tilt);
  final Color color;
  final double t;
  final double tilt;

  @override
  void paint(Canvas canvas, Size size) {
    final rx = size.width / 2 - 2;
    final ry = size.height / 2 - 2;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(tilt);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: rx * 2,
      height: ry * 2,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.5),
    );
    final a = t * 2 * math.pi;
    final dot = Offset(math.cos(a) * rx, math.sin(a) * ry);
    // Rastro curto atrás do ponto.
    for (var i = 1; i <= 10; i++) {
      final b = a - i * 0.035;
      canvas.drawCircle(
        Offset(math.cos(b) * rx, math.sin(b) * ry),
        1.4,
        Paint()..color = color.withValues(alpha: 0.5 * (1 - i / 10)),
      );
    }
    canvas.drawCircle(dot, 3.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t || old.color != color;
}
