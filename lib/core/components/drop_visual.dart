import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/models/drop.dart';
import '../theme/app_theme.dart';

/// Fundo de estúdio: um campo de cor com luz suave, como em foto de produto.
class StudioBackdrop extends StatelessWidget {
  const StudioBackdrop({
    super.key,
    required this.tone,
    this.child,
    this.radius = 0,
    this.spot = const Alignment(-0.45, -0.75),
  });

  final int tone;
  final Widget? child;
  final double radius;
  final Alignment spot;

  /// Cor de texto que contrasta com o fundo de [tone].
  static Color inkOn(int tone) => StudioTones.isLight(tone)
      ? const Color(0xFF0A0A0B)
      : const Color(0xFFF3F3F1);

  @override
  Widget build(BuildContext context) {
    final colors = StudioTones.backdrops[tone % StudioTones.backdrops.length];
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: spot,
              radius: 1.1,
              colors: [
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0),
              ],
            ),
          ),
          child: child ?? const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Imagem de um lançamento.
///
/// Usa a foto cadastrada quando existe; sem foto (ou se ela falhar), mostra
/// a arte de demonstração desenhada em código. Nunca uma foto de terceiros.
class DropVisual extends StatelessWidget {
  const DropVisual({super.key, required this.drop, this.shadow = true});

  final Drop drop;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final art = DropObject(
      art: drop.art,
      tone: drop.tone,
      variant: drop.variant,
      shadow: shadow,
    );
    if (drop.imageUrls.isEmpty) return art;
    return CachedNetworkImage(
      imageUrl: drop.imageUrls.first,
      fit: BoxFit.contain,
      fadeInDuration: Motion.base,
      placeholder: (context, url) => const SizedBox.expand(),
      errorWidget: (context, url, error) => art,
    );
  }
}

/// Arte de demonstração: a silhueta do produto em "metal", desenhada em código.
class DropObject extends StatelessWidget {
  const DropObject({
    super.key,
    required this.art,
    required this.tone,
    this.variant = 0,
    this.shadow = true,
  });

  final DropArt art;
  final int tone;
  final int variant;
  final bool shadow;

  /// Proporção (largura / altura) do desenho de cada silhueta.
  static double aspectOf(DropArt art) {
    final box = _ObjectPainter._boxes[art]!;
    return box.width / box.height;
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ObjectPainter(art, tone, variant, shadow),
        ),
      ),
    );
  }
}

class _ObjectPainter extends CustomPainter {
  _ObjectPainter(this.art, this.tone, this.variant, this.shadow);

  final DropArt art;
  final int tone;
  final int variant;
  final bool shadow;

  static const _boxes = {
    DropArt.sneaker: Size(244, 142),
    DropArt.hoodie: Size(200, 214),
    DropArt.tee: Size(200, 192),
    DropArt.cap: Size(232, 140),
    DropArt.bag: Size(200, 192),
  };

  late final List<Color> _metal =
      StudioTones.metals[tone % StudioTones.metals.length];
  late final bool _lightMetal = _metal[1].computeLuminance() > 0.3;

  Paint get _fill => Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      Offset(_boxes[art]!.width, _boxes[art]!.height),
      _metal,
      const [0, 0.55, 1],
    );

  Paint get _line => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = _lightMetal ? const Color(0x73000000) : const Color(0x59FFFFFF);

  Paint get _lineOnLight => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..strokeCap = StrokeCap.round
    ..color = const Color(0x40000000);

  /// Partes claras: entressola, cadarços, etiquetas.
  Color get _light => Color.lerp(_metal[0], Colors.white, 0.45)!;

  /// Partes em sombra: solado, aba, interior.
  Color get _deep => Color.lerp(_metal[2], Colors.black, 0.4)!;

  Paint get _shadow => Paint()
    ..color = Colors.black.withValues(alpha: 0.36)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

  void _glow(Canvas c, Path clip, Offset at, double r, [double alpha = 0.3]) {
    c.save();
    c.clipPath(clip);
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = ui.Gradient.radial(at, r, [
          Colors.white.withValues(alpha: alpha),
          Colors.white.withValues(alpha: 0),
        ]),
    );
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final box = _boxes[art]!;
    final s = math.min(size.width / box.width, size.height / box.height);
    canvas.translate(
      (size.width - box.width * s) / 2,
      (size.height - box.height * s) / 2,
    );
    canvas.scale(s);
    switch (art) {
      case DropArt.sneaker:
        _sneaker(canvas);
      case DropArt.hoodie:
        _hoodie(canvas);
      case DropArt.tee:
        _tee(canvas);
      case DropArt.cap:
        _cap(canvas);
      case DropArt.bag:
        _bag(canvas);
    }
  }

  void _sneaker(Canvas c) {
    final high = variant % 3 == 1; // cano alto
    final chunky = variant % 3 == 2; // sola robusta
    final lift = high ? 18.0 : 0.0;
    const base = 126.0;
    final top = base - (chunky ? 30.0 : 21.0);

    if (shadow) {
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(122, base + 5),
          width: 228,
          height: 14,
        ),
        _shadow,
      );
    }

    final upper = Path()
      ..moveTo(12, top)
      ..cubicTo(6, top - 16, 11, top - 40 - lift * 0.6, 21, top - 58 - lift)
      ..cubicTo(25, top - 65 - lift, 34, top - 63 - lift, 37, top - 55 - lift)
      ..cubicTo(
        45,
        top - 41 - lift * 0.5,
        62,
        top - 37 - lift * 0.5,
        74,
        top - 47 - lift * 0.6,
      )
      ..cubicTo(
        82,
        top - 55 - lift * 0.8,
        88,
        top - 68 - lift,
        96,
        top - 76 - lift,
      )
      ..cubicTo(
        102,
        top - 81 - lift,
        110,
        top - 78 - lift,
        113,
        top - 71 - lift,
      )
      ..cubicTo(130, top - 55 - lift * 0.5, 150, top - 42, 168, top - 33)
      ..cubicTo(192, top - 25, 214, top - 19, 226, top - 8)
      ..cubicTo(231, top - 3, 232, top + 1, 229, top + 3)
      ..lineTo(12, top + 3)
      ..close();
    c.drawPath(upper, _fill);
    _glow(c, upper, Offset(204, top - 24), 34, 0.34);
    _glow(c, upper, Offset(30, top - 46 - lift), 28, 0.22);

    // Sombra na base do cabedal, junto à entressola.
    c.save();
    c.clipPath(upper);
    c.drawRect(
      Rect.fromLTRB(0, top - 16, 244, top + 4),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top - 16),
          Offset(0, top + 4),
          const [Color(0x00000000), Color(0x38000000)],
        ),
    );
    c.restore();

    final line = _line;
    // Contraforte, painel lateral, gola e biqueira.
    c.drawPath(
      Path()
        ..moveTo(37, top - 55 - lift)
        ..cubicTo(44, top - 36 - lift * 0.4, 48, top - 16, 52, top),
      line,
    );
    c.drawPath(
      Path()
        ..moveTo(52, top)
        ..cubicTo(72, top - 26, 100, top - 36, 126, top - 47 - lift * 0.3),
      line,
    );
    c.drawPath(
      Path()
        ..moveTo(41, top - 46 - lift)
        ..cubicTo(
          49,
          top - 33 - lift * 0.5,
          62,
          top - 29 - lift * 0.5,
          77,
          top - 39 - lift * 0.6,
        ),
      line,
    );
    c.drawPath(
      Path()
        ..moveTo(176, top - 30)
        ..cubicTo(185, top - 22, 191, top - 10, 193, top + 2),
      line,
    );
    // Aba de puxar no calcanhar.
    c.drawPath(
      Path()
        ..moveTo(19, top - 56 - lift)
        ..lineTo(14, top - 69 - lift)
        ..lineTo(21, top - 72 - lift)
        ..lineTo(29, top - 62 - lift)
        ..close(),
      Paint()..color = _deep,
    );

    // Cadarços.
    final l1 = Offset(113, top - 71 - lift);
    final l2 = Offset(168, top - 33);
    final e1 = Offset(103, top - 57 - lift);
    final e2 = Offset(160, top - 20);
    c.drawLine(e1, e2, line);
    final lace = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6
      ..color = _light;
    for (var i = 0; i < 5; i++) {
      final t = 0.12 + i * 0.19;
      c.drawLine(Offset.lerp(l1, l2, t)!, Offset.lerp(e1, e2, t)!, lace);
    }

    // Furos de ventilação.
    c.drawPoints(
      ui.PointMode.points,
      [
        for (var i = 0; i < 3; i++)
          for (var j = 0; j < 2; j++)
            Offset(199 + i * 6.0 - j * 2, top - 15 + j * 6.0),
      ],
      Paint()
        ..color = line.color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Entressola e solado.
    final mid = Path()
      ..moveTo(7, top - 2)
      ..cubicTo(60, top + 4, 170, top + 5, 232, top)
      ..cubicTo(238, top + 3, 239, base - 11, 234, base - 8)
      ..cubicTo(222, base - 2, 206, base, 190, base)
      ..lineTo(22, base)
      ..cubicTo(10, base, 4, base - 6, 5, base - 12)
      ..close();
    c.drawPath(mid, Paint()..color = _light);
    c.save();
    c.clipPath(mid);
    c.drawRect(
      Rect.fromLTRB(0, base - 5, 244, base + 2),
      Paint()..color = _deep,
    );
    c.restore();
    c.drawPath(
      Path()
        ..moveTo(9, top + 6)
        ..cubicTo(60, top + 11, 170, top + 12, 235, top + 7),
      _lineOnLight,
    );
    if (chunky) {
      for (var x = 28.0; x < 100; x += 9) {
        c.drawLine(Offset(x, top + 13), Offset(x - 3, base - 8), _lineOnLight);
      }
    }
  }

  void _hoodie(Canvas c) {
    if (shadow) {
      c.drawOval(
        Rect.fromCenter(center: const Offset(100, 204), width: 150, height: 13),
        _shadow,
      );
    }
    final body = Path()
      ..moveTo(72, 48)
      ..lineTo(42, 60)
      ..cubicTo(27, 66, 20, 80, 17, 100)
      ..lineTo(6, 166)
      ..lineTo(31, 172)
      ..lineTo(48, 106)
      ..lineTo(50, 196)
      ..lineTo(150, 196)
      ..lineTo(152, 106)
      ..lineTo(169, 172)
      ..lineTo(194, 166)
      ..lineTo(183, 100)
      ..cubicTo(180, 80, 173, 66, 158, 60)
      ..lineTo(128, 48)
      ..close();
    c.drawPath(body, _fill);
    _glow(c, body, const Offset(66, 88), 52, 0.26);

    final line = _line;
    final hood = Path()
      ..moveTo(68, 52)
      ..cubicTo(56, 6, 144, 6, 132, 52)
      ..cubicTo(120, 66, 80, 66, 68, 52)
      ..close();
    c.drawPath(hood, _fill);
    c.drawPath(hood, line);
    c.drawPath(
      Path()
        ..moveTo(80, 50)
        ..cubicTo(76, 22, 124, 22, 120, 50)
        ..cubicTo(112, 58, 88, 58, 80, 50)
        ..close(),
      Paint()..color = _deep,
    );

    // Bolso canguru, barra, punhos e costuras das mangas.
    c.drawPath(
      Path()
        ..moveTo(72, 142)
        ..lineTo(128, 142)
        ..lineTo(139, 180)
        ..lineTo(61, 180)
        ..close(),
      line,
    );
    c.drawLine(const Offset(50, 186), const Offset(150, 186), line);
    c.drawLine(const Offset(9, 153), const Offset(34, 159), line);
    c.drawLine(const Offset(166, 159), const Offset(191, 153), line);
    c.drawLine(const Offset(42, 60), const Offset(48, 106), line);
    c.drawLine(const Offset(158, 60), const Offset(152, 106), line);

    // Cordões.
    final cord = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2
      ..color = _light;
    c.drawLine(const Offset(91, 61), const Offset(89, 98), cord);
    c.drawLine(const Offset(109, 61), const Offset(111, 98), cord);
  }

  void _tee(Canvas c) {
    if (shadow) {
      c.drawOval(
        Rect.fromCenter(center: const Offset(100, 183), width: 136, height: 12),
        _shadow,
      );
    }
    final body = Path()
      ..moveTo(74, 30)
      ..lineTo(46, 40)
      ..lineTo(10, 74)
      ..lineTo(28, 100)
      ..lineTo(52, 82)
      ..lineTo(54, 174)
      ..lineTo(146, 174)
      ..lineTo(148, 82)
      ..lineTo(172, 100)
      ..lineTo(190, 74)
      ..lineTo(154, 40)
      ..lineTo(126, 30)
      ..cubicTo(118, 48, 82, 48, 74, 30)
      ..close();
    c.drawPath(body, _fill);
    _glow(c, body, const Offset(70, 76), 50, 0.26);

    final line = _line;
    c.drawPath(
      Path()
        ..moveTo(69, 32)
        ..cubicTo(80, 57, 120, 57, 131, 32),
      line,
    );
    c.drawLine(const Offset(17, 68), const Offset(35, 94), line);
    c.drawLine(const Offset(165, 94), const Offset(183, 68), line);
    c.drawLine(const Offset(54, 166), const Offset(146, 166), line);
    c.drawLine(const Offset(46, 40), const Offset(52, 82), line);
    c.drawLine(const Offset(154, 40), const Offset(148, 82), line);
    // Etiqueta no peito.
    c.drawRRect(
      RRect.fromLTRBR(113, 70, 133, 78, const Radius.circular(2)),
      Paint()..color = _light,
    );
  }

  void _cap(Canvas c) {
    if (shadow) {
      c.drawOval(
        Rect.fromCenter(center: const Offset(122, 128), width: 196, height: 12),
        _shadow,
      );
    }
    final dome = Path()
      ..moveTo(38, 106)
      ..cubicTo(30, 36, 150, 22, 166, 98)
      ..cubicTo(120, 93, 80, 97, 38, 106)
      ..close();
    c.drawPath(dome, _fill);
    _glow(c, dome, const Offset(118, 58), 46, 0.3);

    // Aba: uma cunha que sai da frente da copa, mais fina na ponta.
    final brim = Path()
      ..moveTo(146, 97)
      ..cubicTo(176, 93, 208, 97, 228, 107)
      ..lineTo(227, 112)
      ..cubicTo(206, 106, 176, 106, 148, 110)
      ..close();
    c.drawPath(brim, Paint()..color = _deep);

    final line = _line;
    c.drawPath(
      Path()
        ..moveTo(93, 47)
        ..cubicTo(78, 62, 70, 82, 68, 101),
      line,
    );
    c.drawPath(
      Path()
        ..moveTo(93, 47)
        ..cubicTo(112, 58, 126, 76, 130, 95),
      line,
    );
    c.drawCircle(const Offset(93, 46), 4, Paint()..color = _light);
    c.drawPoints(
      ui.PointMode.points,
      const [Offset(82, 70), Offset(110, 68)],
      Paint()
        ..color = line.color
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    // Regulador traseiro.
    c.drawArc(
      Rect.fromCircle(center: const Offset(47, 104), radius: 9),
      -math.pi * 0.9,
      math.pi * 0.8,
      false,
      line,
    );
  }

  void _bag(Canvas c) {
    if (shadow) {
      c.drawOval(
        Rect.fromCenter(center: const Offset(100, 181), width: 150, height: 12),
        _shadow,
      );
    }
    // Alça.
    c.drawPath(
      Path()
        ..moveTo(52, 80)
        ..cubicTo(52, 2, 148, 2, 148, 80),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round
        ..color = _deep,
    );
    final rect = RRect.fromLTRBR(34, 66, 166, 172, const Radius.circular(20));
    final body = Path()..addRRect(rect);
    c.drawPath(body, _fill);
    _glow(c, body, const Offset(72, 94), 50, 0.28);

    final line = _line;
    c.drawPath(
      Path()
        ..moveTo(34, 98)
        ..cubicTo(70, 128, 130, 128, 166, 98),
      line,
    );
    c.drawRRect(rect.deflate(7), line..strokeWidth = 0.9);
    c.drawRRect(
      RRect.fromLTRBR(91, 112, 109, 129, const Radius.circular(4)),
      Paint()..color = _light,
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = _light;
    c.drawCircle(const Offset(52, 78), 5, ring);
    c.drawCircle(const Offset(148, 78), 5, ring);
  }

  @override
  bool shouldRepaint(_ObjectPainter old) =>
      old.art != art ||
      old.tone != tone ||
      old.variant != variant ||
      old.shadow != shadow;
}
