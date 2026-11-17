import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/components/wordmark.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';

/// Abertura: a retícula do radar "acende" e forma o nome DRIP.
/// Dura menos de dois segundos e segue sozinha para o app.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _c.duration = Duration(milliseconds: context.reduceMotion ? 800 : 1800);
    _c.forward().whenComplete(() {
      if (mounted) ref.read(splashDoneProvider.notifier).finish();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Animation<double> part(double from, double to) => CurvedAnimation(
      parent: _c,
      curve: Interval(from, to, curve: Motion.out),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Semantics(
        label: '${AppConfig.name}. ${AppConfig.tagline}',
        child: ExcludeSemantics(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.x12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: GiantWord(
                            'DRIP',
                            color: c.text,
                            halftone: true,
                            entrance: GiantEntrance.dots,
                          ),
                        ),
                        const SizedBox(width: Space.x3),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: ScaleTransition(
                            scale: part(0.42, 0.72),
                            child: Transform.rotate(
                              angle: math.pi / 4,
                              child: Container(
                                width: 13,
                                height: 13,
                                color: c.silver,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.x6),
                    FadeTransition(
                      opacity: part(0.5, 0.85),
                      child: Text(
                        AppConfig.tagline,
                        textAlign: TextAlign.center,
                        style: DripType.caption.copyWith(color: c.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
