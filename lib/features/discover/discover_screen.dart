import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/components/drip_icon.dart';
import '../../core/components/drop_visual.dart';
import '../../core/components/loading.dart';
import '../../core/components/states.dart';
import '../../core/components/surfaces.dart';
import '../../core/components/wordmark.dart';
import '../../core/config/app_config.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/brand.dart';
import '../../data/models/drop.dart';
import '../../data/providers.dart';
import '../brands/widgets/brand_widgets.dart';
import '../drops/widgets/drop_text.dart';
import '../drops/widgets/drop_tiles.dart';
import '../drops/widgets/status_badge.dart';
import '../shell/app_shell.dart';
import '../want_list/widgets/save_button.dart';
import 'feed.dart';

/// Discover: o radar. Destaques em pôster, depois a linha do tempo dos
/// próximos drops, o que acabou de sair e as marcas.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  static const _barHeight = 52.0;

  final _scroll = ScrollController();

  /// 0 = barra transparente sobre o pôster; 1 = barra translúcida.
  final _bar = ValueNotifier<double>(0);

  /// Cor de texto que contrasta com o pôster visível.
  final _heroInk = ValueNotifier<Color>(const Color(0xFFF3F3F1));
  double _heroH = 520;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final top = MediaQuery.paddingOf(context).top;
      final start = _heroH - top - _barHeight - 28;
      _bar.value = ((_scroll.offset - start) / 28).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _bar.dispose();
    _heroInk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final feed = ref.watch(feedProvider);
    final brands = ref.watch(brandsProvider).value ?? const <Brand>[];
    final now = ref.watch(nowProvider);
    _heroH = (size.height * 0.68).clamp(440.0, 620.0);

    ref.listen(tabReselectProvider, (_, next) {
      if (next.index == 0 && _scroll.hasClients) {
        _scroll.animateTo(0, duration: Motion.slow, curve: Motion.out);
      }
    });

    return ColoredBox(
      color: c.bg,
      child: Stack(
        children: [
          feed.when(
            loading: () => _Loading(heroHeight: _heroH),
            error: (error, _) => Center(
              child: ErrorState(
                message:
                    'Não conseguimos buscar os lançamentos. Confira sua '
                    'conexão e tente de novo.',
                onRetry: () => ref.invalidate(dropsProvider),
              ),
            ),
            data: (feed) {
              if (feed.isEmpty) {
                return const Center(
                  child: EmptyState(
                    glyph: DripGlyph.radar,
                    title: 'O radar está vazio',
                    message:
                        'Ainda não há lançamentos cadastrados. Assim que a '
                        'equipe do DRIP publicar o primeiro drop, ele aparece '
                        'aqui.',
                  ),
                );
              }
              return CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _HeroPager(
                      drops: feed.featured,
                      height: _heroH,
                      onInk: (ink) => _heroInk.value = ink,
                    ),
                  ),
                  if (brands.isNotEmpty)
                    SliverToBoxAdapter(child: _BrandTicker(brands: brands)),
                  SliverToBoxAdapter(
                    child: Reveal(
                      delay: const Duration(milliseconds: 260),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (feed.live.isNotEmpty) ...[
                            const SizedBox(height: Space.x8),
                            SectionTitle(
                              'Ao vivo agora',
                              count: feed.live.length,
                            ),
                            for (final d in feed.live)
                              DropRow(drop: d, slot: 'live'),
                          ],
                          const SizedBox(height: Space.x8),
                          SectionTitle(
                            'Próximos drops',
                            count: feed.upcoming.length,
                            actionLabel: 'Ver todos',
                            onAction: () => context.go(Routes.explore),
                          ),
                          if (feed.upcoming.isEmpty)
                            const EmptyState(
                              title: 'Nenhum drop com data marcada',
                              message:
                                  'Quando uma marca confirmar a próxima data, '
                                  'ela entra nesta linha do tempo.',
                              padding: EdgeInsets.fromLTRB(
                                Space.gutter,
                                0,
                                Space.gutter,
                                Space.x4,
                              ),
                            )
                          else
                            for (final g in feed.upcomingByDay)
                              _DayGroup(day: g.day, drops: g.drops, now: now),
                        ],
                      ),
                    ),
                  ),
                  if (feed.tbd.isNotEmpty) ...[
                    const SliverToBoxAdapter(child: SizedBox(height: Space.x8)),
                    SliverToBoxAdapter(
                      child: SectionTitle(
                        'Anunciados, sem data',
                        count: feed.tbd.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: DropCardStrip(drops: feed.tbd, slot: 'tbd'),
                    ),
                  ],
                  if (feed.released.isNotEmpty) ...[
                    const SliverToBoxAdapter(child: SizedBox(height: Space.x8)),
                    SliverToBoxAdapter(
                      child: SectionTitle(
                        'Lançados há pouco',
                        count: feed.released.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: DropCardStrip(drops: feed.released, slot: 'out'),
                    ),
                  ],
                  if (brands.isNotEmpty) ...[
                    const SliverToBoxAdapter(child: SizedBox(height: Space.x8)),
                    SliverToBoxAdapter(
                      child: SectionTitle(
                        'Marcas no radar',
                        count: brands.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.textScalerOf(context).scale(18) + 82,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.gutter - 8,
                          ),
                          itemCount: brands.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 4),
                          itemBuilder: (_, i) => BrandBubble(brand: brands[i]),
                        ),
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: _Footer(
                      demo: ref.watch(catalogRepositoryProvider).isDemo,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: insets.bottom + Space.x6),
                  ),
                ],
              );
            },
          ),

          // Barra do topo: transparente sobre o pôster, translúcida depois.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: insets.top + _barHeight,
            child: ListenableBuilder(
              listenable: Listenable.merge([_bar, _heroInk]),
              builder: (context, _) {
                final t = _bar.value;
                final onHero = feed.value != null && !feed.value!.isEmpty;
                final ink = onHero
                    ? Color.lerp(_heroInk.value, c.text, t)!
                    : c.text;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (t > 0)
                      Opacity(
                        opacity: t,
                        child: const Glass(
                          edge: GlassEdge.bottom,
                          child: SizedBox.expand(),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Space.gutter,
                        insets.top,
                        Space.gutter,
                        0,
                      ),
                      child: Row(
                        children: [
                          DripWordmark(height: 19, color: ink, diamond: ink),
                          const Spacer(),
                          Semantics(
                            label: 'Hoje, ${Fmt.spokenDate(now)}',
                            excludeSemantics: true,
                            child: Text(
                              '${Fmt.weekday(now)} ${Fmt.dayMonth(now)}',
                              style: DripType.label.copyWith(color: ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Pôsteres dos destaques: deslize para o lado para ver o próximo.
class _HeroPager extends StatefulWidget {
  const _HeroPager({
    required this.drops,
    required this.height,
    required this.onInk,
  });

  final List<Drop> drops;
  final double height;
  final ValueChanged<Color> onInk;

  @override
  State<_HeroPager> createState() => _HeroPagerState();
}

class _HeroPagerState extends State<_HeroPager> {
  final _pages = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportInk());
  }

  @override
  void didUpdateWidget(_HeroPager old) {
    super.didUpdateWidget(old);
    if (_index >= widget.drops.length) _index = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportInk());
  }

  void _reportInk() {
    if (!mounted || widget.drops.isEmpty) return;
    widget.onInk(StudioBackdrop.inkOn(widget.drops[_index].tone));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drops = widget.drops;
    if (drops.isEmpty) return SizedBox(height: widget.height * 0.3);
    final ink = StudioBackdrop.inkOn(drops[_index].tone);
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: drops.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _reportInk();
            },
            itemBuilder: (context, i) => _HeroPoster(
              drop: drops[i],
              index: i,
              controller: _pages,
              height: widget.height,
            ),
          ),
          if (drops.length > 1)
            Positioned(
              left: Space.gutter,
              bottom: Space.x5,
              child: Semantics(
                label: 'Destaque ${_index + 1} de ${drops.length}',
                child: Row(
                  children: [
                    for (var i = 0; i < drops.length; i++)
                      AnimatedContainer(
                        duration: Motion.base,
                        curve: Motion.out,
                        margin: const EdgeInsets.only(right: 5),
                        width: i == _index ? 24 : 7,
                        height: 3,
                        decoration: BoxDecoration(
                          color: ink.withValues(alpha: i == _index ? 1 : 0.35),
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroPoster extends ConsumerWidget {
  const _HeroPoster({
    required this.drop,
    required this.index,
    required this.controller,
    required this.height,
  });

  final Drop drop;
  final int index;
  final PageController controller;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final ink = StudioBackdrop.inkOn(drop.tone);
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final tag = 'hero-${drop.id}';
    final wordTop = top + 62;

    // Camadas em velocidades diferentes ao deslizar: profundidade.
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
            offset: Offset(delta * width * factor, 0),
            child: inner,
          );
        },
        child: child,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        StudioBackdrop(tone: drop.tone),
        Positioned(
          top: wordTop,
          left: 14,
          right: 14,
          child: parallax(
            0.42,
            GiantWord(
              drop.poster,
              color: ink,
              entrance: index == 0 ? GiantEntrance.rise : GiantEntrance.none,
              delay: const Duration(milliseconds: 80),
              maxHeight: height * 0.26,
              alignment: Alignment.center,
            ),
          ),
        ),
        Positioned(
          top: wordTop + height * 0.11,
          left: 22,
          right: 22,
          bottom: 138,
          child: parallax(
            -0.16,
            Hero(
              tag: tag,
              child: Transform.rotate(
                angle: drop.art == DropArt.sneaker ? -0.1 : 0,
                child: DropVisual(drop: drop),
              ),
            ),
          ),
        ),
        // Tocar em qualquer ponto do pôster abre o drop.
        Positioned.fill(
          child: Semantics(
            button: true,
            label: drop.spoken(now),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => openDrop(context, drop, tag),
            ),
          ),
        ),
        Positioned(
          left: Space.gutter,
          right: Space.x3,
          bottom: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(drop.statusAt(now), ink: ink),
                        const SizedBox(height: 6),
                        Text(
                          drop.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DripType.title.copyWith(
                            fontSize: 27,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${drop.brandName}  ·  ${drop.whenLine(now)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DripType.data.copyWith(
                            color: ink.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.x2),
              SaveButton(drop: drop, style: SaveStyle.glass, ink: ink),
            ],
          ),
        ),
      ],
    );
  }
}

/// Faixa com os nomes das marcas, deslizando devagar.
class _BrandTicker extends StatelessWidget {
  const _BrandTicker({required this.brands});
  final List<Brand> brands;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: Space.x5),
      child: MediaQuery.withNoTextScaling(
        child: Marquee(
          pixelsPerSecond: 34,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final b in brands) ...[
                GiantWord(b.name, color: c.text, height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(width: 8, height: 8, color: c.silver),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Um dia da linha do tempo: a data à esquerda, os drops à direita.
class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.day, required this.drops, required this.now});

  final DateTime day;
  final List<Drop> drops;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final days = Fmt.calendarDays(now, day);
    final weekday = Fmt.weekday(day);
    final hint = switch (days) {
      0 => 'Hoje',
      1 => 'Amanhã',
      _ => weekday[0] + weekday.substring(1).toLowerCase(),
    };
    return Padding(
      padding: const EdgeInsets.only(left: Space.gutter, bottom: Space.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Semantics(
              header: true,
              label: Fmt.spokenDate(day),
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Fmt.day(day),
                      style: DripType.dataL.copyWith(color: c.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Fmt.month(day),
                      style: DripType.label.copyWith(color: c.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      maxLines: 1,
                      softWrap: false,
                      style: DripType.footnote.copyWith(
                        color: days <= 1 ? c.silver : c.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                for (final d in drops)
                  DropRow(
                    drop: d,
                    slot: 'up',
                    timeOnly: true,
                    padding: const EdgeInsets.fromLTRB(0, 6, Space.x2, 6),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fecho da tela: o nome da marca em retícula, de borda a borda.
class _Footer extends StatelessWidget {
  const _Footer({required this.demo});
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.x16,
        Space.gutter,
        Space.x4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GiantWord('DRIP', color: c.text, halftone: true),
          const SizedBox(height: Space.x4),
          Text(
            AppConfig.tagline,
            style: DripType.body.copyWith(color: c.textMuted),
          ),
          if (demo) ...[
            const SizedBox(height: Space.x2),
            Text(
              'Conteúdo de demonstração: marcas e produtos fictícios, usados '
              'só para apresentar o app.',
              style: DripType.footnote.copyWith(color: c.textFaint),
            ),
          ],
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.heroHeight});
  final double heroHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando lançamentos',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Skeleton(height: heroHeight, radius: 0),
          const SizedBox(height: Space.x10),
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                Space.gutter,
                0,
                Space.gutter,
                Space.x4,
              ),
              child: Row(
                children: [
                  Skeleton(width: 72, height: 72),
                  SizedBox(width: Space.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(width: 160, height: 18),
                        SizedBox(height: 8),
                        Skeleton(width: 110, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
