import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';

/// Estilingue para lançar um drop na Want List.
///
/// A pessoa agarra a bolinha, puxa (o elástico estica como uma membrana de
/// borracha entre o soquete e a bolinha) e solta. Um puxão forte o bastante
/// lança a bolinha na direção oposta, solta faíscas e chama
/// [onAddedToWantList]; um puxão fraco só devolve a bolinha ao soquete.
///
/// Leitores de tela e teclado acionam o lançamento direto (ação "tocar").
class WantListSlingshot extends StatefulWidget {
  const WantListSlingshot({
    super.key,
    required this.onAddedToWantList,
    this.onCycleComplete,
    this.height = 300,
    this.semanticLabel = 'Lançar na Want List',
  });

  /// Chamado no instante do lançamento válido.
  final VoidCallback onAddedToWantList;

  /// Chamado quando a confirmação termina e a bolinha volta ao soquete.
  final VoidCallback? onCycleComplete;
  final double height;
  final String semanticLabel;

  @override
  State<WantListSlingshot> createState() => _WantListSlingshotState();
}

enum _Phase { idle, dragging, flying, confirming }

class _Spark {
  _Spark(this.p, this.v, this.life, this.size) : maxLife = life;
  Offset p;
  Offset v;
  double life;
  final double maxLife;
  final double size;
}

class _WantListSlingshotState extends State<WantListSlingshot>
    with SingleTickerProviderStateMixin {
  // Geometria e física (adaptadas do Slingshot da Bencho).
  static const rSocket = 38.0;
  static const rBall = 29.0;
  static const pull = 118.0;
  static const notches = 8;
  static const shake = 0.7;
  static const gravity = 700.0;
  static const bounce = 0.3;

  /// Tensão mínima (0–1) para o lançamento valer.
  static const minLaunch = 0.35;

  // Mola do elástico: subamortecida (passa do centro e volta).
  static const _k = 520.0;
  static const _damping = 16.0;

  // Tempos da confirmação.
  static const _flightTime = 1.1;
  static const _checkHold = 0.85;
  static const _respawn = 0.35;

  late final Ticker _ticker = createTicker(_tick);
  final _repaint = ValueNotifier<int>(0);
  final _rnd = math.Random();

  Duration _last = Duration.zero;
  double _time = 0;
  Size _size = Size.zero;
  bool _laidOut = false;

  _Phase _phase = _Phase.idle;
  Offset _ball = Offset.zero;
  Offset _ballVel = Offset.zero;
  double _ballScale = 1;
  double _ballOpacity = 1;
  Offset _tip = Offset.zero;
  Offset _tipVel = Offset.zero;
  Offset _grab = Offset.zero;
  double _tension = 0;
  int _stage = 0;
  double _phaseTime = 0;
  final _sparks = <_Spark>[];

  Offset get _center => Offset(_size.width / 2, _size.height - 96);

  // ---- Curva de borracha ----------------------------------------------

  static double _tanh(double x) {
    final e = math.exp(2 * x);
    return (e - 1) / (e + 1);
  }

  /// Até 60% do alcance acompanha o dedo; depois endurece (tanh).
  static double _rubber(double d) {
    const soft = pull * 0.6;
    if (d <= soft) return d;
    return soft + (pull - soft) * _tanh((d - soft) / (pull - soft));
  }

  // ---- Laço de física -------------------------------------------------

  void _wake() {
    if (_ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    var dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0) return;
    dt = math.min(dt, 1 / 30);
    _time += dt;
    _phaseTime += dt;
    final center = _center;

    // Ponta livre do elástico: volta ao centro com mola subamortecida.
    if (_phase != _Phase.dragging) {
      final a = (center - _tip) * _k - _tipVel * _damping;
      _tipVel += a * dt;
      _tip += _tipVel * dt;
    }

    switch (_phase) {
      case _Phase.idle:
        // Puxão fraco: a bolinha vai junto com o elástico.
        _ball = _tip;
      case _Phase.dragging:
        break;
      case _Phase.flying:
        _fly(dt);
        if (_phaseTime > _flightTime - 0.25) {
          _ballOpacity = (1 - (_phaseTime - (_flightTime - 0.25)) / 0.25).clamp(
            0.0,
            1.0,
          );
        }
        if (_phaseTime >= _flightTime) {
          _phase = _Phase.confirming;
          _phaseTime = 0;
          _ballOpacity = 0;
        }
      case _Phase.confirming:
        if (_phaseTime >= _checkHold) {
          // A bolinha reaparece no soquete.
          _ball = center;
          _ballVel = Offset.zero;
          final t = ((_phaseTime - _checkHold) / _respawn).clamp(0.0, 1.0);
          _ballOpacity = t;
          _ballScale = Curves.easeOutBack.transform(t);
          if (t >= 1) {
            _phase = _Phase.idle;
            _ballScale = 1;
            _ballOpacity = 1;
            widget.onCycleComplete?.call();
          }
        }
    }

    // Faíscas: desaceleram, caem um pouco e somem.
    for (final s in _sparks) {
      s.v = s.v * math.exp(-4.5 * dt) + Offset(0, 260 * dt);
      s.p += s.v * dt;
      s.life -= dt;
    }
    _sparks.removeWhere((s) => s.life <= 0);

    final resting = (_tip - center).distance < 0.3 && _tipVel.distance < 2;
    if (_phase == _Phase.idle && _sparks.isEmpty && resting) {
      _tip = center;
      _tipVel = Offset.zero;
      _ball = center;
      _ticker.stop();
    }
    _repaint.value++;
  }

  void _fly(double dt) {
    _ballVel += const Offset(0, gravity) * dt;
    var p = _ball + _ballVel * dt;
    var v = _ballVel;
    final minX = rBall, maxX = _size.width - rBall;
    final minY = rBall, maxY = _size.height - rBall;
    if (p.dx < minX || p.dx > maxX) {
      p = Offset(p.dx.clamp(minX, maxX), p.dy);
      v = Offset(-v.dx * bounce, v.dy);
    }
    if (p.dy < minY || p.dy > maxY) {
      p = Offset(p.dx, p.dy.clamp(minY, maxY));
      // No chão, o atrito freia o rolamento.
      v = Offset(v.dx * 0.9, -v.dy * bounce);
    }
    _ball = p;
    _ballVel = v;
  }

  // ---- Gestos ---------------------------------------------------------

  bool _hitsBall(Offset local) =>
      _phase == _Phase.idle && (local - _ball).distance <= rBall + 18;

  void _onStart(DragStartDetails d) {
    if (!_hitsBall(d.localPosition)) return;
    _phase = _Phase.dragging;
    _grab = d.localPosition - _center;
    _stage = 0;
    _tension = 0;
    _tipVel = Offset.zero;
    _wake();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_phase != _Phase.dragging) return;
    final raw = d.localPosition - _grab - _center;
    final dist = raw.distance;
    final mapped = _rubber(dist);
    final dir = dist > 0 ? raw / dist : Offset.zero;
    _ball = _center + dir * mapped;
    _tip = _ball;
    _tension = (mapped / pull).clamp(0.0, 1.0);
    // Um "clique" a cada entalhe ultrapassado ao esticar.
    final stage = (_tension * notches).floor().clamp(0, notches);
    if (stage > _stage) HapticFeedback.selectionClick();
    _stage = stage;
  }

  void _onEnd([DragEndDetails? _]) {
    if (_phase != _Phase.dragging) return;
    if (_tension >= minLaunch) {
      _launch();
    } else {
      _phase = _Phase.idle;
      _tipVel = Offset.zero;
    }
    _wake();
  }

  void _launch() {
    final away = _ball - _center;
    final dist = away.distance;
    final dir = dist > 0 ? -away / dist : const Offset(0, -1);
    // Velocidade proporcional ao quadrado da tensão.
    final speed = 380 + 2300 * _tension * _tension;
    _ballVel = dir * speed;
    _phase = _Phase.flying;
    _phaseTime = 0;
    _ballOpacity = 1;
    _ballScale = 1;
    // O elástico solta junto, com um empurrão para o centro.
    _tip = _ball;
    _tipVel = dir * speed * 0.35;
    _burst(_ball, dir);
    HapticFeedback.mediumImpact();
    widget.onAddedToWantList();
    _wake();
  }

  /// Leque de ~100° de faíscas na direção do lançamento.
  void _burst(Offset at, Offset dir) {
    final base = math.atan2(dir.dy, dir.dx);
    const spread = 100 * math.pi / 180;
    final count = 25 + _rnd.nextInt(12);
    for (var i = 0; i < count; i++) {
      final a = base + (_rnd.nextDouble() - 0.5) * spread;
      final sp = 140 + _rnd.nextDouble() * 340;
      _sparks.add(
        _Spark(
          at + Offset(math.cos(a), math.sin(a)) * rBall * 0.6,
          Offset(math.cos(a), math.sin(a)) * sp,
          0.38 + _rnd.nextDouble() * 0.14,
          1 + _rnd.nextDouble() * 1.8,
        ),
      );
    }
  }

  /// Leitor de tela / teclado: lança direto, com 80% de tensão para cima.
  void _autoLaunch() {
    if (_phase != _Phase.idle) return;
    _tension = 0.8;
    _ball = _center + Offset(0, _rubber(pull * 0.8));
    _launch();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return LayoutBuilder(
      builder: (context, cons) {
        final size = Size(cons.maxWidth, widget.height);
        if (size != _size) {
          _size = size;
          if (!_laidOut || (_phase == _Phase.idle && !_ticker.isActive)) {
            _ball = _center;
            _tip = _center;
          }
          _laidOut = true;
        }
        return Semantics(
          button: true,
          label: widget.semanticLabel,
          hint: 'Puxe a bolinha e solte para lançar',
          onTap: _autoLaunch,
          excludeSemantics: true,
          child: RawGestureDetector(
            gestures: {
              _EagerPan: GestureRecognizerFactoryWithHandlers<_EagerPan>(
                () => _EagerPan(_hitsBall),
                (r) => r
                  ..onStart = _onStart
                  ..onUpdate = _onUpdate
                  ..onEnd = _onEnd
                  ..onCancel = _onEnd,
              ),
            },
            child: CustomPaint(
              size: size,
              painter: _SlingshotPainter(
                this,
                socket: c.surface,
                line: c.line,
                rubber: c.surfaceHigh,
                ball: c.accent,
                arrow: c.onAccent,
                spark: c.text,
                success: c.success,
                onSuccess: c.bg,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Aceita o arrasto já no toque quando ele cai na bolinha, para a folha e
/// a rolagem em volta não roubarem o gesto.
class _EagerPan extends PanGestureRecognizer {
  _EagerPan(this._hits);

  final bool Function(Offset local) _hits;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (_hits(event.localPosition)) resolve(GestureDisposition.accepted);
  }
}

class _SlingshotPainter extends CustomPainter {
  _SlingshotPainter(
    this.s, {
    required this.socket,
    required this.line,
    required this.rubber,
    required this.ball,
    required this.arrow,
    required this.spark,
    required this.success,
    required this.onSuccess,
  }) : super(repaint: s._repaint);

  final _WantListSlingshotState s;
  final Color socket, line, rubber, ball, arrow, spark, success, onSuccess;

  static const r1 = _WantListSlingshotState.rSocket;
  static const r2 = _WantListSlingshotState.rBall;

  @override
  void paint(Canvas canvas, Size size) {
    final center = s._center;
    final tip = s._tip;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = line;

    // Soquete.
    canvas.drawCircle(center, r1, Paint()..color = socket);

    // Cápsula elástica entre o soquete e a ponta livre.
    final hull = _hull(center, tip);
    if (hull != null) {
      final t = s._phase == _Phase.dragging ? s._tension : 0.0;
      canvas.drawPath(
        hull,
        Paint()..color = Color.lerp(rubber, line, t * 0.6)!,
      );
      canvas.drawPath(hull, stroke);
    } else {
      canvas.drawCircle(center, r1, stroke);
    }
    // Fundo do soquete, levemente mais escuro que a borracha.
    canvas.drawCircle(
      center,
      r1 * 0.55,
      Paint()..color = line.withValues(alpha: 0.35),
    );

    // Faíscas.
    for (final p in s._sparks) {
      canvas.drawCircle(
        p.p,
        p.size,
        Paint()..color = spark.withValues(alpha: (p.life / p.maxLife) * 0.9),
      );
    }

    // Confirmação.
    if (s._phase == _Phase.confirming) {
      final t = (s._phaseTime / 0.5).clamp(0.0, 1.0);
      final fade = s._phaseTime < 0.85
          ? 1.0
          : (1 - (s._phaseTime - 0.85) / 0.2).clamp(0.0, 1.0);
      _check(canvas, center, Curves.elasticOut.transform(t), fade);
    }

    // Bolinha.
    if (s._ballOpacity > 0 && s._ballScale > 0) {
      var at = s._ball;
      final away = s._ball - center;
      final dist = away.distance;
      final dir = dist > 0 ? away / dist : Offset.zero;
      if (s._phase == _Phase.dragging && s._tension > 0.9) {
        // Tremor senoidal perto do limite.
        final perp = Offset(-dir.dy, dir.dx);
        at +=
            perp *
            math.sin(s._time * 2 * math.pi * 22) *
            _WantListSlingshotState.shake;
      }
      final r = r2 * s._ballScale;
      canvas.drawCircle(
        at,
        r,
        Paint()..color = ball.withValues(alpha: s._ballOpacity),
      );
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.45, -0.6),
            radius: 0.9,
            colors: [
              const Color(0xFFFFFFFF).withValues(alpha: 0.28 * s._ballOpacity),
              const Color(0x00FFFFFF),
            ],
          ).createShader(Rect.fromCircle(center: at, radius: r)),
      );

      // Seta: aponta para onde a bolinha vai (oposto ao puxão).
      final launching = s._phase == _Phase.flying
          ? s._ballVel
          : (dist > 1 ? -away : const Offset(0, -1));
      final angle = math.atan2(launching.dy, launching.dx) + math.pi / 2;
      _arrow(canvas, at, angle, s._ballScale, s._ballOpacity);
    }
  }

  /// Une os dois círculos pelas tangentes externas e pelos arcos de fora,
  /// formando uma cápsula única que estica.
  Path? _hull(Offset c1, Offset c2) {
    final d = (c2 - c1).distance;
    if (d <= r1 - r2 + 0.5) return null;
    final theta = math.atan2(c2.dy - c1.dy, c2.dx - c1.dx);
    final phi = math.acos(((r1 - r2) / d).clamp(-1.0, 1.0));
    Offset on(Offset c, double r, double a) =>
        c + Offset(math.cos(a), math.sin(a)) * r;
    final p1a = on(c1, r1, theta + phi);
    final p2a = on(c2, r2, theta + phi);
    return Path()
      ..moveTo(p1a.dx, p1a.dy)
      ..lineTo(p2a.dx, p2a.dy)
      // Arco de fora da bolinha (passa por theta).
      ..arcTo(
        Rect.fromCircle(center: c2, radius: r2),
        theta + phi,
        -2 * phi,
        false,
      )
      // Volta pela outra tangente até o soquete...
      ..lineTo(on(c1, r1, theta - phi).dx, on(c1, r1, theta - phi).dy)
      // ...e fecha pelo arco de fora do soquete (passa por theta + pi).
      ..arcTo(
        Rect.fromCircle(center: c1, radius: r1),
        theta - phi,
        -(2 * math.pi - 2 * phi),
        false,
      )
      ..close();
  }

  /// Seta "para cima" (como `Icons.arrow_upward_rounded`), desenhada em
  /// vetor para não depender da fonte de ícones já ter carregado.
  void _arrow(Canvas canvas, Offset at, double angle, double scale, double a) {
    final u = 10.5 * scale;
    final path = Path()
      ..moveTo(0, u)
      ..lineTo(0, -u)
      ..moveTo(-u * 0.72, -u * 0.28)
      ..lineTo(0, -u)
      ..lineTo(u * 0.72, -u * 0.28);
    canvas
      ..save()
      ..translate(at.dx, at.dy)
      ..rotate(angle)
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6 * scale
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = arrow.withValues(alpha: a),
      )
      ..restore();
  }

  void _check(Canvas canvas, Offset at, double scale, double alpha) {
    if (scale <= 0 || alpha <= 0) return;
    final r = r2 * scale;
    canvas.drawCircle(at, r, Paint()..color = success.withValues(alpha: alpha));
    final path = Path()
      ..moveTo(at.dx - r * 0.38, at.dy + r * 0.02)
      ..lineTo(at.dx - r * 0.1, at.dy + r * 0.3)
      ..lineTo(at.dx + r * 0.42, at.dy - r * 0.28);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * scale.clamp(0.0, 1.2)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = onSuccess.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(_SlingshotPainter old) =>
      old.ball != ball || old.socket != socket || old.line != line;
}
