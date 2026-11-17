import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Ícones próprios do DRIP: traço fino, pontas arredondadas, grade 24.
/// Desenhados em código para manter um único peso de linha em todo o app.
enum DripGlyph {
  radar,
  search,
  bookmark,
  bookmarkFilled,
  bell,
  user,
  arrowLeft,
  arrowRight,
  arrowUpRight,
  chevronRight,
  close,
  sliders,
  check,
  plus,
  clock,
  calendar,
  eye,
  eyeOff,
  logout,
  mail,
  lock,
  moon,
  shield,
  info,
  diamond,
  settings,
  tag,
}

class DripIcon extends StatelessWidget {
  const DripIcon(
    this.glyph, {
    super.key,
    this.size = 22,
    this.color,
    this.stroke = 1.6,
  });

  final DripGlyph glyph;
  final double size;
  final Color? color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFFFFFFFF);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GlyphPainter(glyph, c, stroke)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color, this.stroke);
  final DripGlyph glyph;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final f = Paint()..color = color;

    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);
    void poly(List<double> pts, {bool close = false, Paint? paint}) {
      final path = Path()..moveTo(pts[0], pts[1]);
      for (var i = 2; i < pts.length; i += 2) {
        path.lineTo(pts[i], pts[i + 1]);
      }
      if (close) path.close();
      canvas.drawPath(path, paint ?? p);
    }

    void circle(double x, double y, double r, {Paint? paint}) =>
        canvas.drawCircle(Offset(x, y), r, paint ?? p);
    void rrect(double l, double t, double r, double b, double rad) =>
        canvas.drawRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(rad)), p);
    void arc(double x, double y, double r, double start, double sweep) =>
        canvas.drawArc(
          Rect.fromCircle(center: Offset(x, y), radius: r),
          start,
          sweep,
          false,
          p,
        );

    switch (glyph) {
      case DripGlyph.radar:
        circle(12, 12, 9);
        arc(12, 12, 5, -math.pi / 2, math.pi * 1.5);
        line(12, 12, 18.2, 5.8);
        circle(12, 12, 1.3, paint: f);
      case DripGlyph.search:
        circle(11, 11, 6.5);
        line(16, 16, 20.5, 20.5);
      case DripGlyph.bookmark:
        poly([6.5, 4, 17.5, 4, 17.5, 20, 12, 15.6, 6.5, 20], close: true);
      case DripGlyph.bookmarkFilled:
        poly([6.5, 4, 17.5, 4, 17.5, 20, 12, 15.6, 6.5, 20], close: true);
        poly(
          [6.5, 4, 17.5, 4, 17.5, 20, 12, 15.6, 6.5, 20],
          close: true,
          paint: f,
        );
      case DripGlyph.bell:
        final path = Path()
          ..moveTo(5, 17)
          ..quadraticBezierTo(7, 15, 7, 11)
          ..cubicTo(7, 4.5, 17, 4.5, 17, 11)
          ..quadraticBezierTo(17, 15, 19, 17)
          ..close();
        canvas.drawPath(path, p);
        arc(12, 18.4, 2, 0.15, math.pi - 0.3);
      case DripGlyph.user:
        circle(12, 8.5, 3.6);
        arc(12, 21.5, 7.2, math.pi * 1.12, math.pi * 0.76);
      case DripGlyph.arrowLeft:
        line(19, 12, 5, 12);
        poly([11, 6, 5, 12, 11, 18]);
      case DripGlyph.arrowRight:
        line(5, 12, 19, 12);
        poly([13, 6, 19, 12, 13, 18]);
      case DripGlyph.arrowUpRight:
        line(7, 17, 17, 7);
        poly([9, 7, 17, 7, 17, 15]);
      case DripGlyph.chevronRight:
        poly([9.5, 6, 15.5, 12, 9.5, 18]);
      case DripGlyph.close:
        line(6.5, 6.5, 17.5, 17.5);
        line(17.5, 6.5, 6.5, 17.5);
      case DripGlyph.sliders:
        line(4, 8, 6.7, 8);
        line(11.3, 8, 20, 8);
        circle(9, 8, 2.3);
        line(4, 16, 12.7, 16);
        line(17.3, 16, 20, 16);
        circle(15, 16, 2.3);
      case DripGlyph.check:
        poly([5.5, 12.5, 10, 17, 18.5, 7.5]);
      case DripGlyph.plus:
        line(12, 5.5, 12, 18.5);
        line(5.5, 12, 18.5, 12);
      case DripGlyph.clock:
        circle(12, 12, 8.5);
        poly([12, 7.5, 12, 12, 15.2, 14]);
      case DripGlyph.calendar:
        rrect(4.5, 6, 19.5, 19.5, 2.5);
        line(4.5, 10.5, 19.5, 10.5);
        line(8.5, 3.8, 8.5, 7.2);
        line(15.5, 3.8, 15.5, 7.2);
      case DripGlyph.eye:
        final path = Path()
          ..moveTo(3, 12)
          ..quadraticBezierTo(12, 2.5, 21, 12)
          ..quadraticBezierTo(12, 21.5, 3, 12);
        canvas.drawPath(path, p);
        circle(12, 12, 2.8);
      case DripGlyph.eyeOff:
        final path = Path()
          ..moveTo(3, 12)
          ..quadraticBezierTo(12, 2.5, 21, 12)
          ..quadraticBezierTo(12, 21.5, 3, 12);
        canvas.drawPath(path, p);
        line(5, 4.5, 19, 19.5);
      case DripGlyph.logout:
        poly([10, 4.5, 5, 4.5, 5, 19.5, 10, 19.5]);
        line(10.5, 12, 19.5, 12);
        poly([15.5, 8, 19.5, 12, 15.5, 16]);
      case DripGlyph.mail:
        rrect(3.5, 6, 20.5, 18, 2.5);
        poly([4.5, 7.5, 12, 13, 19.5, 7.5]);
      case DripGlyph.lock:
        rrect(5.5, 10.5, 18.5, 20, 2.5);
        final path = Path()
          ..moveTo(8.5, 10.5)
          ..lineTo(8.5, 8)
          ..cubicTo(8.5, 3.2, 15.5, 3.2, 15.5, 8)
          ..lineTo(15.5, 10.5);
        canvas.drawPath(path, p);
      case DripGlyph.moon:
        final path = Path()
          ..moveTo(19, 14.2)
          ..arcToPoint(
            const Offset(9.8, 5),
            radius: const Radius.circular(7.4),
            clockwise: true,
          )
          ..arcToPoint(
            const Offset(19, 14.2),
            radius: const Radius.circular(8),
            largeArc: true,
            clockwise: false,
          );
        canvas.drawPath(path, p);
      case DripGlyph.shield:
        final path = Path()
          ..moveTo(12, 3.5)
          ..lineTo(19, 6.2)
          ..lineTo(19, 11.5)
          ..quadraticBezierTo(19, 17.5, 12, 20.5)
          ..quadraticBezierTo(5, 17.5, 5, 11.5)
          ..lineTo(5, 6.2)
          ..close();
        canvas.drawPath(path, p);
      case DripGlyph.info:
        circle(12, 12, 8.5);
        line(12, 11, 12, 16.2);
        circle(12, 7.9, 0.9, paint: f);
      case DripGlyph.diamond:
        poly([7.5, 4.5, 16.5, 4.5, 21, 9.5, 12, 20, 3, 9.5], close: true);
        line(3, 9.5, 21, 9.5);
        poly([9.5, 4.5, 8, 9.5, 12, 20, 16, 9.5, 14.5, 4.5]);
      case DripGlyph.settings:
        // Engrenagem: contorno com oito dentes e o furo central.
        const teeth = 8;
        const step = 2 * math.pi / teeth;
        final gear = Path();
        for (var i = 0; i < teeth; i++) {
          final a = i * step - math.pi / 2;
          for (final (offset, radius) in const [
            (-0.32, 6.6),
            (-0.17, 9.2),
            (0.17, 9.2),
            (0.32, 6.6),
          ]) {
            final x = 12 + math.cos(a + offset * step) * radius;
            final y = 12 + math.sin(a + offset * step) * radius;
            if (i == 0 && offset == -0.32) {
              gear.moveTo(x, y);
            } else {
              gear.lineTo(x, y);
            }
          }
        }
        gear.close();
        canvas.drawPath(gear, p);
        circle(12, 12, 2.9);
      case DripGlyph.tag:
        poly([4, 4, 12, 4, 20.5, 12.5, 12.5, 20.5, 4, 12], close: true);
        circle(8.3, 8.3, 1.2, paint: f);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color || old.stroke != stroke;
}
