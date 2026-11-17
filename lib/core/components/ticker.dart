import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

Widget _rollTransition(Widget child, Animation<double> anim, bool incoming) {
  final slide = Tween<Offset>(
    begin: incoming ? const Offset(0, 0.85) : const Offset(0, -0.85),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: anim, curve: Motion.out));
  return ClipRect(
    child: SlideTransition(
      position: slide,
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}

/// Texto que "rola" caractere por caractere quando muda (contadores).
/// Só o que mudou se move; algarismos tabulares mantêm a largura estável.
class RollingText extends StatelessWidget {
  const RollingText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return Text(text, style: style);
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < text.length; i++)
              AnimatedSwitcher(
                // A posição conta a partir do fim: unidades ficam estáveis.
                key: ValueKey('cell-${text.length - i}'),
                duration: Motion.base,
                reverseDuration: Motion.base,
                transitionBuilder: (child, anim) => _rollTransition(
                  child,
                  anim,
                  child.key == ValueKey(text[i]),
                ),
                child: Text(text[i], key: ValueKey(text[i]), style: style),
              ),
          ],
        ),
      ),
    );
  }
}

/// Alterna palavras no mesmo lugar: a atual sobe e some, a próxima entra
/// por baixo. Com "reduzir movimento", mostra só a primeira.
class FlipWords extends StatefulWidget {
  const FlipWords({
    super.key,
    required this.words,
    required this.style,
    this.interval = const Duration(milliseconds: 2200),
  });

  final List<String> words;
  final TextStyle style;
  final Duration interval;

  @override
  State<FlipWords> createState() => _FlipWordsState();
}

class _FlipWordsState extends State<FlipWords> {
  Timer? _timer;
  int _i = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (!context.reduceMotion && widget.words.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (mounted) setState(() => _i = (_i + 1) % widget.words.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.words.join(', '),
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: Motion.slow,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previous, ?current],
          ),
          transitionBuilder: (child, anim) =>
              _rollTransition(child, anim, child.key == ValueKey(_i)),
          child: Text(
            widget.words[_i],
            key: ValueKey(_i),
            maxLines: 1,
            style: widget.style,
          ),
        ),
      ),
    );
  }
}

/// Reconstrói a cada segundo com o tempo que falta até [target].
class CountdownBuilder extends StatefulWidget {
  const CountdownBuilder({
    super.key,
    required this.target,
    required this.builder,
  });

  final DateTime target;
  final Widget Function(BuildContext context, Duration left) builder;

  @override
  State<CountdownBuilder> createState() => _CountdownBuilderState();
}

class _CountdownBuilderState extends State<CountdownBuilder> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.target.difference(DateTime.now());
    return widget.builder(context, left.isNegative ? Duration.zero : left);
  }
}
