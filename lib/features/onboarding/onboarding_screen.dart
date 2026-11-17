import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/components/buttons.dart';
import '../../core/components/drip_icon.dart';
import '../../core/components/drop_visual.dart';
import '../../core/components/stamp.dart';
import '../../core/components/ticker.dart';
import '../../core/components/wordmark.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/drop.dart';
import '../../data/providers.dart';
import '../discover/feed.dart';

class _Step {
  const _Step({
    required this.word,
    required this.title,
    required this.body,
    required this.tone,
    this.art,
    this.variant = 0,
    this.flip,
  });

  /// Palavras que se alternam logo depois do título (opcional).
  final List<String>? flip;
  final String word;
  final String title;
  final String body;
  final int tone;

  /// Silhueta mostrada; `null` = o selo com a contagem do próximo drop.
  final DropArt? art;
  final int variant;
}

const _steps = [
  _Step(
    word: 'DESCUBRA',
    title: 'Um só radar para',
    flip: ['sneakers.', 'streetwear.', 'collabs.', 'drops.'],
    body: 'Sneakers e streetwear em ordem de lançamento, com a curadoria do DRIP.',
    tone: 0,
    art: DropArt.sneaker,
    variant: 2,
  ),
  _Step(
    word: 'SALVE',
    title: 'Guarde o que você quer.',
    body: 'Monte sua Want List e acompanhe as marcas que importam para você.',
    tone: 5,
    art: DropArt.hoodie,
  ),
  _Step(
    word: 'CHEGUE',
    title: 'Esteja lá quando abrir.',
    body: 'Avisos antes de cada drop e o link direto para o site oficial da marca.',
    tone: 1,
  ),
];

/// Três telas curtas que apresentam a proposta. Dá para pular a qualquer hora.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  bool get _last => _index == _steps.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish({required bool signup}) {
    ref.read(onboardingSeenProvider.notifier).complete();
    final router = GoRouter.of(context);
    router.go(Routes.login);
    if (signup) router.push(Routes.signup);
  }

  void _next() {
    if (_last) {
      _finish(signup: true);
      return;
    }
    if (context.reduceMotion) {
      _pages.jumpToPage(_index + 1);
    } else {
      _pages.nextPage(duration: Motion.slow, curve: Motion.out);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final insets = MediaQuery.paddingOf(context);
    final ink = StudioBackdrop.inkOn(_steps[_index].tone);

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: _steps.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _StepView(
              step: _steps[i],
              index: i,
              controller: _pages,
              position: i + 1,
            ),
          ),

          // Topo: marca e "Pular".
          Positioned(
            top: insets.top + Space.x2,
            left: Space.gutter,
            right: Space.x2,
            child: Row(
              children: [
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: ink),
                  duration: Motion.base,
                  builder: (context, color, _) =>
                      DripWordmark(height: 18, color: color, diamond: color),
                ),
                const Spacer(),
                AnimatedOpacity(
                  opacity: _last ? 0 : 1,
                  duration: Motion.base,
                  child: IgnorePointer(
                    ignoring: _last,
                    child: DripButton(
                      label: 'Pular',
                      kind: DripButtonKind.ghost,
                      foreground: ink,
                      expand: false,
                      compact: true,
                      semanticLabel: 'Pular a apresentação',
                      onTap: () => _finish(signup: false),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Base: progresso e ações.
          Positioned(
            left: Space.x6,
            right: Space.x6,
            bottom: insets.bottom + Space.x5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Passo ${_index + 1} de ${_steps.length}',
                  child: Row(
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        AnimatedContainer(
                          duration: Motion.base,
                          curve: Motion.out,
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _index ? 28 : 8,
                          height: 4,
                          decoration: BoxDecoration(
                            color: i == _index ? c.text : c.line,
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.x5),
                DripButton(
                  label: _last ? 'Criar conta' : 'Continuar',
                  trailing: _last ? null : DripGlyph.arrowRight,
                  onTap: _next,
                ),
                SoftSize(
                  child: _last
                      ? Padding(
                          padding: const EdgeInsets.only(top: Space.x1),
                          child: DripButton(
                            label: 'Já tenho conta',
                            kind: DripButtonKind.ghost,
                            foreground: c.text,
                            onTap: () => _finish(signup: false),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepView extends ConsumerWidget {
  const _StepView({
    required this.step,
    required this.index,
    required this.controller,
    required this.position,
  });

  final _Step step;
  final int index;
  final PageController controller;
  final int position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final ink = StudioBackdrop.inkOn(step.tone);
    // Em telas baixas a imagem encolhe para o texto e os botões caberem.
    final visualH = math
        .min(size.height * 0.54, size.height - 410)
        .clamp(170.0, 620.0)
        .toDouble();

    // Quanto esta página está deslocada do centro (-1 a 1): move as camadas
    // em velocidades diferentes ao arrastar.
    Widget parallax(double factor, Widget child) {
      if (context.reduceMotion) return child;
      return AnimatedBuilder(
        animation: controller,
        builder: (context, inner) {
          var delta = 0.0;
          if (controller.hasClients && controller.position.haveDimensions) {
            delta = (controller.page ?? index.toDouble()) - index;
          }
          return Transform.translate(
            offset: Offset(delta * size.width * factor, 0),
            child: inner,
          );
        },
        child: child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: visualH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              StudioBackdrop(tone: step.tone),
              Positioned(
                top: top + 76,
                left: Space.x4,
                right: Space.x4,
                child: parallax(
                  0.35,
                  GiantWord(
                    step.word,
                    color: ink,
                    entrance: index == 0
                        ? GiantEntrance.rise
                        : GiantEntrance.none,
                    delay: const Duration(milliseconds: 120),
                    maxHeight: visualH * 0.3,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              Positioned(
                left: Space.x8,
                right: Space.x8,
                // O tênis sobe até encostar na palavra: tipografia e produto
                // se sobrepõem, em vez de ficarem empilhados.
                top:
                    top +
                    76 +
                    visualH * (step.art == DropArt.sneaker ? 0.05 : 0.16),
                bottom: Space.x5,
                child: parallax(
                  -0.18,
                  step.art == null
                      ? Center(child: _NextDropStamp(ink: ink))
                      : Align(
                          alignment: step.art == DropArt.sneaker
                              ? Alignment.topCenter
                              : Alignment.center,
                          child: AspectRatio(
                            aspectRatio: DropObject.aspectOf(step.art!),
                            child: Transform.rotate(
                              angle: step.art == DropArt.sneaker ? -0.12 : 0,
                              child: DropObject(
                                art: step.art!,
                                tone: step.tone,
                                variant: step.variant,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.x6, Space.x6, Space.x6, 0),
            child: Semantics(
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      step.title,
                      style: DripType.title.copyWith(
                        fontSize: 28,
                        color: c.text,
                      ),
                    ),
                  ),
                  // A última palavra do título se alterna sozinha,
                  // mostrando tudo o que o radar cobre.
                  if (step.flip != null)
                    FlipWords(
                      words: step.flip!,
                      style: DripType.title.copyWith(
                        fontSize: 28,
                        color: c.silver,
                      ),
                    ),
                  const SizedBox(height: Space.x3),
                  Text(
                    step.body,
                    style: DripType.bodyL.copyWith(color: c.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// O selo com a contagem real para o próximo drop do catálogo.
class _NextDropStamp extends ConsumerWidget {
  const _NextDropStamp({required this.ink});
  final Color ink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(feedProvider).value?.upcoming ?? const <Drop>[];
    final next = upcoming.isEmpty ? null : upcoming.first;
    final at = next?.releaseAt;

    return LayoutBuilder(
      builder: (context, box) {
        final side = box.biggest.shortestSide.clamp(120.0, 232.0);
        if (next == null || at == null) {
          return CircularStamp(
            text: 'Próximo drop em breve',
            size: side,
            color: ink,
            child: Text(
              'EM BREVE',
              style: DripType.labelL.copyWith(color: ink),
            ),
          );
        }
        return CircularStamp(
          text: '${next.name} · ${Fmt.dayMonth(at)}',
          size: side,
          color: ink,
          child: CountdownBuilder(
            target: at,
            builder: (context, left) {
              final t = Fmt.countdown(left);
              final days = left.inDays > 0;
              return Semantics(
                label: 'Próximo drop ${Fmt.untilText(at, DateTime.now())}',
                excludeSemantics: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RollingText(
                      days ? '${t.d}d ${t.h}h' : '${t.h}:${t.m}:${t.s}',
                      style: DripType.dataL.copyWith(
                        color: ink,
                        fontSize: side * 0.14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PARA ABRIR',
                      style: DripType.label.copyWith(color: ink),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
