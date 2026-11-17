import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Carregamento único do shader `shaders/liquid_glass.frag`.
///
/// O vidro com refração só existe onde o Flutter aceita shader como filtro
/// de fundo (motor Impeller: Android e iOS). Na web e enquanto o shader
/// carrega, [LiquidGlassContainer] usa o fallback: desfoque + borda especular.
abstract final class LiquidGlass {
  static final ValueNotifier<ui.FragmentProgram?> program = ValueNotifier(null);
  static Future<void>? _loading;

  /// Desliga o shader (testes, depuração). O fallback continua funcionando.
  static bool enabled = true;

  static bool get supported =>
      enabled && ui.ImageFilter.isShaderFilterSupported;

  /// Começa a carregar o shader. Pode ser chamado várias vezes.
  static Future<void> preload() {
    if (!supported) return Future.value();
    return _loading ??=
        ui.FragmentProgram.fromAsset(
          'shaders/liquid_glass.frag',
        ).then<void>((p) => program.value = p).catchError((Object e) {
          debugPrint('[DRIP] Liquid Glass indisponível, usando fallback: $e');
        });
  }
}

/// Superfície de vidro líquido: refração de lente na borda, aberração
/// cromática, luz especular de cima à esquerda e tinta do tema.
///
/// Vira superfície sólida quando o sistema pede alto contraste.
class LiquidGlassContainer extends StatelessWidget {
  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(50)),
    this.blurSigma = 8,
    this.bendIntensity = 1,
    this.padding,
    this.tint,
    this.tintStrength = 0.55,
    this.shadow = false,
    this.rim = true,
    this.shapeOverflow = EdgeInsets.zero,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Desfoque do fundo antes da refração.
  final double blurSigma;

  /// 0 = sem curvatura; 1 = padrão; 2 = vidro bem grosso.
  final double bendIntensity;
  final EdgeInsetsGeometry? padding;

  /// Cor do material (padrão: `glass` do tema).
  final Color? tint;

  /// Quanto da tinta cobre o fundo (0–1).
  final double tintStrength;

  /// Sombra difusa por fora do vidro.
  final bool shadow;

  /// Filete especular no contorno (fallback). Barras de borda a borda
  /// desligam e usam só o fio de separação.
  final bool rim;

  /// Estende a forma do vidro além do recorte visível. Serve para barras e
  /// folhas presas numa borda da tela: o lado colado à tela não curva.
  final EdgeInsets shapeOverflow;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    final base = tint ?? c.glass;

    Widget glass;
    if (MediaQuery.highContrastOf(context)) {
      glass = ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.bg, borderRadius: borderRadius),
          position: DecorationPosition.background,
          child: content,
        ),
      );
    } else {
      glass = ValueListenableBuilder<ui.FragmentProgram?>(
        valueListenable: LiquidGlass.program,
        builder: (context, program, _) {
          if (program != null && LiquidGlass.supported) {
            return ClipRRect(
              borderRadius: borderRadius,
              child: _ShaderGlass(
                program: program,
                radius: borderRadius.topLeft.x,
                blurSigma: blurSigma,
                bend: bendIntensity,
                dark: dark,
                tint: base.withValues(alpha: 1),
                tintStrength: base.a * tintStrength / 0.75,
                overflow: shapeOverflow,
                devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                child: content,
              ),
            );
          }
          return ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: blurSigma + 12,
                sigmaY: blurSigma + 12,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: borderRadius,
                ),
                child: rim
                    ? CustomPaint(
                        foregroundPainter: SpecularRimPainter(
                          borderRadius: borderRadius,
                          dark: dark,
                        ),
                        child: content,
                      )
                    : content,
              ),
            ),
          );
        },
      );
    }

    if (!shadow) return glass;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000)
                .withValues(alpha: dark ? 0.42 : 0.14),
            blurRadius: 32,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: glass,
    );
  }
}

/// Contorno de 1px com brilho vindo de cima à esquerda e um reflexo mais
/// fraco na borda oposta. É o "vidro" do fallback e também serve sozinho.
class SpecularRimPainter extends CustomPainter {
  const SpecularRimPainter({required this.borderRadius, required this.dark});

  final BorderRadius borderRadius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const white = Color(0xFFFFFFFF);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: const Alignment(-0.55, -0.85),
        end: const Alignment(0.55, 0.85),
        colors: [
          white.withValues(alpha: dark ? 0.42 : 0.9),
          white.withValues(alpha: dark ? 0.06 : 0.25),
          white.withValues(alpha: 0),
          white.withValues(alpha: dark ? 0.16 : 0.4),
        ],
        stops: const [0, 0.32, 0.62, 1],
      ).createShader(rect);
    canvas.drawRRect(borderRadius.toRRect(rect).deflate(0.5), paint);
  }

  @override
  bool shouldRepaint(SpecularRimPainter old) =>
      old.dark != dark || old.borderRadius != borderRadius;
}

/// Liga o shader a um [BackdropFilterLayer] e repinta quando um rolamento
/// acima dele muda a posição na tela.
class _ShaderGlass extends StatefulWidget {
  const _ShaderGlass({
    required this.program,
    required this.radius,
    required this.blurSigma,
    required this.bend,
    required this.dark,
    required this.tint,
    required this.tintStrength,
    required this.overflow,
    required this.devicePixelRatio,
    required this.child,
  });

  final ui.FragmentProgram program;
  final double radius;
  final double blurSigma;
  final double bend;
  final bool dark;
  final Color tint;
  final double tintStrength;
  final EdgeInsets overflow;
  final double devicePixelRatio;
  final Widget child;

  @override
  State<_ShaderGlass> createState() => _ShaderGlassState();
}

class _ShaderGlassState extends State<_ShaderGlass> {
  final _key = GlobalKey();
  final _positions = <ScrollPosition>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final p in _positions) {
      p.removeListener(_moved);
    }
    _positions.clear();
    // Todos os roláveis acima (ex.: carrossel dentro de lista).
    var ctx = context;
    while (true) {
      final s = Scrollable.maybeOf(ctx);
      if (s == null) break;
      _positions.add(s.position..addListener(_moved));
      ctx = s.context;
    }
  }

  void _moved() {
    final r = _key.currentContext?.findRenderObject();
    if (r is RenderObject && r.attached) r.markNeedsPaint();
  }

  @override
  void dispose() {
    for (final p in _positions) {
      p.removeListener(_moved);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _LiquidGlassFilter(
    key: _key,
    program: widget.program,
    radius: widget.radius,
    blurSigma: widget.blurSigma,
    bend: widget.bend,
    dark: widget.dark,
    tint: widget.tint,
    tintStrength: widget.tintStrength,
    overflow: widget.overflow,
    devicePixelRatio: widget.devicePixelRatio,
    child: widget.child,
  );
}

class _LiquidGlassFilter extends SingleChildRenderObjectWidget {
  const _LiquidGlassFilter({
    super.key,
    required this.program,
    required this.radius,
    required this.blurSigma,
    required this.bend,
    required this.dark,
    required this.tint,
    required this.tintStrength,
    required this.overflow,
    required this.devicePixelRatio,
    super.child,
  });

  final ui.FragmentProgram program;
  final double radius;
  final double blurSigma;
  final double bend;
  final bool dark;
  final Color tint;
  final double tintStrength;
  final EdgeInsets overflow;
  final double devicePixelRatio;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLiquidGlass(program.fragmentShader())..update(this);

  @override
  void updateRenderObject(BuildContext context, _RenderLiquidGlass r) =>
      r.update(this);
}

class _RenderLiquidGlass extends RenderProxyBox {
  _RenderLiquidGlass(this._shader);

  final ui.FragmentShader _shader;
  double _radius = 0;
  double _blur = 0;
  double _bend = 1;
  bool _dark = true;
  static const _extraBlur = 4.0;

  Color _tint = const Color(0xFF000000);
  double _tintStrength = 0.5;
  EdgeInsets _overflow = EdgeInsets.zero;
  double _dpr = 1;

  void update(_LiquidGlassFilter w) {
    _radius = w.radius;
    // Um pouco de desfoque a mais e de tinta deixam o vidro legível sobre
    // fundos movimentados. Vidro aninhado (blurSigma 0) já recebe o fundo
    // desfocado do vidro de fora, então fica sem.
    _blur = w.blurSigma > 0 ? w.blurSigma + _extraBlur : 0;
    _bend = w.bend;
    _dark = w.dark;
    _tint = w.tint;
    _tintStrength = (w.tintStrength * 1.12).clamp(0.0, 1.0);
    _overflow = w.overflow;
    _dpr = w.devicePixelRatio;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final origin = localToGlobal(Offset.zero);
    final s = _dpr;
    final w = size.width + _overflow.horizontal;
    final h = size.height + _overflow.vertical;
    final minSide = (size.width < size.height ? size.width : size.height) / 2;
    final r = _radius.clamp(0.0, minSide);
    final bevel = (r > 0 ? r : minSide) * 0.6 + 4;

    _shader
      ..setFloat(2, (origin.dx - _overflow.left) * s)
      ..setFloat(3, (origin.dy - _overflow.top) * s)
      ..setFloat(4, w * s)
      ..setFloat(5, h * s)
      ..setFloat(6, r * s)
      ..setFloat(7, bevel * s)
      ..setFloat(8, 9 * _bend * s)
      ..setFloat(9, _dark ? 1 : 0)
      ..setFloat(10, _tint.r)
      ..setFloat(11, _tint.g)
      ..setFloat(12, _tint.b)
      ..setFloat(13, _tintStrength);

    var filter = ui.ImageFilter.shader(_shader);
    if (_blur > 0) {
      filter = ui.ImageFilter.compose(
        outer: filter,
        inner: ui.ImageFilter.blur(
          sigmaX: _blur,
          sigmaY: _blur,
          tileMode: TileMode.clamp,
        ),
      );
    }
    final l = (layer as BackdropFilterLayer?) ?? BackdropFilterLayer();
    l.filter = filter;
    layer = l;
    context.pushLayer(l, super.paint, offset);
  }

  @override
  void dispose() {
    _shader.dispose();
    super.dispose();
  }
}
