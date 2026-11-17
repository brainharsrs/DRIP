import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Como a palavra gigante entra em cena.
enum GiantEntrance {
  /// Já aparece pronta.
  none,

  /// Sobe de trás de uma máscara.
  rise,

  /// A retícula de pontos "acende" da esquerda para a direita.
  dots,
}

/// Palavra gigante em caixa alta: a tipografia como imagem.
///
/// Encaixa a palavra na largura disponível (ou numa [height] fixa) colando a
/// caixa no topo das maiúsculas, para compor sem folgas. Com [halftone], as
/// letras são preenchidas por uma retícula de pontos (o "radar" do DRIP).
///
/// É decorativa: o leitor de tela a ignora. Dê o significado em outro lugar.
class GiantWord extends StatefulWidget {
  const GiantWord(
    this.text, {
    super.key,
    required this.color,
    this.halftone = false,
    this.entrance = GiantEntrance.none,
    this.delay = Duration.zero,
    this.height,
    this.maxHeight,
    this.alignment = Alignment.centerLeft,
  });

  final String text;
  final Color color;
  final bool halftone;
  final GiantEntrance entrance;
  final Duration delay;

  /// Altura fixa das maiúsculas. Se nula, a palavra ocupa a largura toda.
  final double? height;

  /// Teto de altura quando a palavra é dimensionada pela largura.
  final double? maxHeight;
  final Alignment alignment;

  @override
  State<GiantWord> createState() => _GiantWordState();
}

class _GiantWordState extends State<GiantWord>
    with SingleTickerProviderStateMixin {
  static const _base = 100.0;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.delay + Motion.reveal,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMilliseconds /
          (widget.delay + Motion.reveal).inMilliseconds,
      1,
      curve: Motion.out,
    ),
  );

  TextPainter? _tp;
  String? _key;

  @override
  void initState() {
    super.initState();
    if (widget.entrance == GiantEntrance.none) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _tp?.dispose();
    super.dispose();
  }

  TextPainter _painter() {
    final word = widget.text.toUpperCase();
    final key = '$word|${widget.color.toARGB32()}';
    if (_tp != null && _key == key) return _tp!;
    _tp?.dispose();
    _key = key;
    return _tp = TextPainter(
      text: TextSpan(
        text: word,
        style: TextStyle(
          fontFamily: DripType.family,
          fontSize: _base,
          height: 1,
          letterSpacing: -1.2,
          color: widget.color,
          fontWeight: FontWeight.w900,
          fontVariations: const [
            FontVariation('wght', DripType.giantWeight),
            FontVariation('wdth', DripType.giantWidth),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  @override
  Widget build(BuildContext context) {
    final tp = _painter();
    // Acentos em maiúsculas (É, Ã) precisam de espaço extra acima.
    final accented = widget.text.runes.any((r) => r > 127);
    final above = (accented ? 0.95 : 0.715) * _base;
    const below = 0.03 * _base;
    final boxH = above + below;
    final reduce = context.reduceMotion;

    Widget paint(double scale) {
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) => Opacity(
            opacity: reduce ? _t.value.clamp(0.0, 1.0) : 1,
            child: CustomPaint(
              size: Size(tp.width * scale, boxH * scale),
              painter: _GiantPainter(
                tp: tp,
                scale: scale,
                above: above,
                color: widget.color,
                halftone: widget.halftone,
                entrance: reduce ? GiantEntrance.none : widget.entrance,
                t: _t.value,
              ),
            ),
          ),
        ),
      );
    }

    final fixed = widget.height;
    return ExcludeSemantics(
      child: fixed != null
          ? paint(fixed / boxH)
          : LayoutBuilder(
              builder: (context, box) {
                var scale = box.maxWidth / tp.width;
                final cap = widget.maxHeight;
                if (cap != null && boxH * scale > cap) scale = cap / boxH;
                return Align(
                  alignment: widget.alignment,
                  heightFactor: 1,
                  child: paint(scale),
                );
              },
            ),
    );
  }
}

class _GiantPainter extends CustomPainter {
  _GiantPainter({
    required this.tp,
    required this.scale,
    required this.above,
    required this.color,
    required this.halftone,
    required this.entrance,
    required this.t,
  });

  final TextPainter tp;
  final double scale;
  final double above;
  final Color color;
  final bool halftone;
  final GiantEntrance entrance;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = tp.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final origin = Offset(0, above - baseline);
    final bounds = Rect.fromLTWH(0, 0, tp.width, size.height / scale);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (entrance == GiantEntrance.rise) {
      canvas.translate(0, (1 - t) * size.height * 1.04);
    }
    canvas.scale(scale);

    if (!halftone) {
      tp.paint(canvas, origin);
      canvas.restore();
      return;
    }

    // Retícula: desenha os pontos e usa a palavra como máscara.
    const pitch = 3.5;
    canvas.saveLayer(bounds, Paint());
    final growing = entrance == GiantEntrance.dots && t < 1;
    const levels = 5;
    final buckets = List.generate(levels + 1, (_) => <Offset>[]);
    for (var y = pitch / 2; y < bounds.height; y += pitch) {
      for (var x = pitch / 2; x < bounds.width; x += pitch) {
        var p = 1.0;
        if (growing) {
          final lag = (x / bounds.width) * 0.55 + (y / bounds.height) * 0.12;
          p = ((t * 1.67 - lag) / 0.55).clamp(0.0, 1.0);
        }
        buckets[(p * levels).round()].add(Offset(x, y));
      }
    }
    final dot = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= levels; i++) {
      if (buckets[i].isEmpty) continue;
      dot.strokeWidth = pitch * 0.78 * (i / levels);
      canvas.drawPoints(ui.PointMode.points, buckets[i], dot);
    }
    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
    tp.paint(canvas, origin);
    canvas.restore();
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GiantPainter old) =>
      old.t != t ||
      old.tp != tp ||
      old.scale != scale ||
      old.color != color ||
      old.halftone != halftone ||
      old.entrance != entrance;
}

/// Wordmark **temporário** do DRIP: nome em caixa alta + um pequeno diamante
/// no lugar do ponto final (aceno discreto ao brinco de diamante da marca).
///
/// Quando o logo oficial existir em `assets/branding/`, troque o conteúdo
/// deste widget e o app inteiro passa a usá-lo.
class DripWordmark extends StatelessWidget {
  const DripWordmark({super.key, this.height = 20, this.color, this.diamond});

  /// Altura das letras.
  final double height;
  final Color? color;
  final Color? diamond;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final side = height * 0.27;
    return Semantics(
      label: 'DRIP',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GiantWord('DRIP', color: color ?? c.text, height: height),
            SizedBox(width: height * 0.16),
            Padding(
              // A ponta de baixo do diamante encosta na linha de base.
              padding: EdgeInsets.only(bottom: side * 0.21),
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: side,
                  height: side,
                  color: diamond ?? c.silver,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
