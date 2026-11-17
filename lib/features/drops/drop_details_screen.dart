import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/components/buttons.dart';
import '../../core/components/chips.dart';
import '../../core/components/drip_icon.dart';
import '../../core/components/drop_visual.dart';
import '../../core/components/loading.dart';
import '../../core/components/stamp.dart';
import '../../core/components/states.dart';
import '../../core/components/surfaces.dart';
import '../../core/components/ticker.dart';
import '../../core/components/wordmark.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/links.dart';
import '../../data/models/drop.dart';
import '../../data/providers.dart';
import '../brands/widgets/brand_widgets.dart';
import '../want_list/widgets/save_button.dart';
import 'widgets/drop_text.dart';
import 'widgets/drop_tiles.dart';
import 'widgets/status_badge.dart';

/// Detalhe de um drop: galeria, dados do lançamento, a marca e o caminho
/// para o site oficial. O DRIP não vende: o botão principal leva à marca.
class DropDetailsScreen extends ConsumerStatefulWidget {
  const DropDetailsScreen({super.key, required this.dropId, this.heroTag});

  final String dropId;

  /// Etiqueta do Hero de onde a imagem "voou" (lista ou pôster).
  final String? heroTag;

  @override
  ConsumerState<DropDetailsScreen> createState() => _DropDetailsScreenState();
}

class _DropDetailsScreenState extends ConsumerState<DropDetailsScreen> {
  static const _barHeight = 52.0;

  final _scroll = ScrollController();
  final _bar = ValueNotifier<double>(0);
  double _heroH = 460;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final top = MediaQuery.paddingOf(context).top;
      final start = _heroH - top - _barHeight - 24;
      _bar.value = ((_scroll.offset - start) / 24).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _bar.dispose();
    super.dispose();
  }

  void _back() =>
      context.canPop() ? context.pop() : context.go(Routes.discover);

  Future<void> _openSite(Uri uri) async {
    final ok = await ref.read(linkOpenerProvider)(uri);
    if (!ok && mounted) {
      showToast(
        context,
        'Não foi possível abrir o site agora. Tente de novo em instantes.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final drop = ref.watch(dropByIdProvider(widget.dropId));

    if (drop == null) {
      final catalog = ref.watch(dropsProvider);
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(Space.x2),
                child: IconPill(
                  glyph: DripGlyph.arrowLeft,
                  label: 'Voltar',
                  onTap: _back,
                ),
              ),
              Expanded(
                child: Center(
                  child: catalog.isLoading && !catalog.hasValue
                      ? const DripLoader()
                      : EmptyState(
                          glyph: DripGlyph.radar,
                          title: 'Drop não encontrado',
                          message:
                              'Este lançamento pode ter sido removido do '
                              'catálogo ou o link está incompleto.',
                          actionLabel: 'Voltar',
                          onAction: _back,
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final now = ref.watch(nowProvider);
    final DropStatus status = drop.statusAt(now);
    final brand = ref.watch(brandByIdProvider(drop.brandId));
    final related = ref
        .watch(dropsOfBrandProvider(drop.brandId))
        .where((d) => d.id != drop.id)
        .toList();
    final uri = Links.parse(drop.officialUrl);
    final tag = widget.heroTag ?? 'detail-${drop.id}';
    _heroH = (size.height * 0.56).clamp(360.0, 580.0);

    final hint = uri == null
        ? 'O link oficial deste drop ainda não está disponível.'
        : switch (status) {
            DropStatus.upcoming =>
              'Vendas a partir de ${drop.whenLine(now)} em ${Links.host(uri)}',
            DropStatus.live => 'Aberto agora em ${Links.host(uri)}',
            DropStatus.released =>
              'Você sai do DRIP e vai para ${Links.host(uri)}',
            DropStatus.tbd => 'Acompanhe a data em ${Links.host(uri)}',
          };

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: _Gallery(
                  drop: drop,
                  status: status,
                  now: now,
                  heroTag: tag,
                  height: _heroH,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.x5,
                    Space.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusBadge(status),
                      const SizedBox(height: Space.x2),
                      Semantics(
                        header: true,
                        child: Text(
                          drop.name,
                          style: DripType.largeTitle.copyWith(color: c.text),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(-2, 0),
                        child: Pressable(
                          onTap: () => context.push(Routes.brand(drop.brandId)),
                          semanticLabel: 'Ver a marca ${drop.brandName}',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  drop.brandName.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DripType.labelL.copyWith(
                                    color: c.text,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              DripIcon(
                                DripGlyph.chevronRight,
                                size: 15,
                                color: c.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                drop.category.label,
                                style: DripType.caption.copyWith(
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.x4),
                      _FactSheet(drop: drop),
                      const SizedBox(height: Space.x6),
                      Text(
                        drop.description,
                        style: DripType.bodyL.copyWith(color: c.text),
                      ),
                    ],
                  ),
                ),
              ),
              if (brand != null) ...[
                const SliverToBoxAdapter(child: SizedBox(height: Space.x8)),
                const SliverToBoxAdapter(child: SectionTitle('A marca')),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BrandRow(brand: brand),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.gutter,
                          Space.x2,
                          Space.gutter,
                          0,
                        ),
                        child: Text(
                          brand.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: DripType.body.copyWith(color: c.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (related.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: Space.x8)),
                SliverToBoxAdapter(
                  child: SectionTitle(
                    'Mais de ${drop.brandName}',
                    count: related.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: DropCardStrip(drops: related, slot: 'rel'),
                ),
              ],
              SliverToBoxAdapter(child: SizedBox(height: insets.bottom + 148)),
            ],
          ),

          // Barra do topo: voltar e salvar, sempre à mão.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: insets.top + _barHeight,
            child: ValueListenableBuilder<double>(
              valueListenable: _bar,
              builder: (context, t, _) => Stack(
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
                      Space.x2,
                      insets.top,
                      Space.x2,
                      0,
                    ),
                    child: Row(
                      children: [
                        IconPill(
                          glyph: DripGlyph.arrowLeft,
                          label: 'Voltar',
                          glass: t < 1,
                          onTap: _back,
                        ),
                        Expanded(
                          child: Opacity(
                            opacity: t,
                            child: ExcludeSemantics(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Space.x2,
                                ),
                                child: Text(
                                  drop.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DripType.subhead.copyWith(
                                    color: c.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SaveButton(
                          drop: drop,
                          slingshot: true,
                          style: t < 1 ? SaveStyle.glass : SaveStyle.plain,
                          ink: c.text,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ação principal: ir ao site oficial da marca.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Glass(
              edge: GlassEdge.top,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.x3,
                  Space.gutter,
                  insets.bottom + Space.x3,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DripButton(
                      label: 'Comprar no site da marca',
                      trailing: DripGlyph.arrowUpRight,
                      onTap: uri == null ? null : () => _openSite(uri),
                    ),
                    const SizedBox(height: Space.x2),
                    Text(
                      hint,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: DripType.footnote.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ficha do lançamento: data, hora, preço e cores, em um único quadro.
class _FactSheet extends StatelessWidget {
  const _FactSheet({required this.drop});
  final Drop drop;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget cell(String caption, String value) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x3 + 2,
        ),
        child: FactCell(caption: caption, value: value),
      ),
    );
    final vLine = Container(width: 0.8, color: c.line);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                cell('Data', drop.dateValue),
                vLine,
                cell('Hora', drop.timeValue),
              ],
            ),
          ),
          const Hairline(),
          IntrinsicHeight(
            child: Row(
              children: [
                cell('Preço', drop.priceValue),
                vLine,
                cell('Cores', drop.colorway ?? '—'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Galeria do drop. Com fotos cadastradas, mostra as fotos; sem fotos,
/// três composições feitas com a arte de demonstração.
class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.drop,
    required this.status,
    required this.now,
    required this.heroTag,
    required this.height,
  });

  final Drop drop;
  final DropStatus status;
  final DateTime now;
  final String heroTag;
  final double height;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drop = widget.drop;
    final ink = StudioBackdrop.inkOn(drop.tone);
    final top = MediaQuery.paddingOf(context).top;
    final photos = drop.imageUrls;

    final slides = photos.isNotEmpty
        ? [
            for (var i = 0; i < photos.length; i++)
              Padding(
                padding: EdgeInsets.fromLTRB(20, top + 64, 20, 56),
                child: i == 0
                    ? Hero(
                        tag: widget.heroTag,
                        child: DropVisual(drop: drop),
                      )
                    : CachedNetworkImage(
                        imageUrl: photos[i],
                        fit: BoxFit.contain,
                        fadeInDuration: Motion.base,
                        errorWidget: (_, _, _) => Center(
                          child: DripIcon(
                            DripGlyph.info,
                            color: ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
              ),
          ]
        : [
            _PosterSlide(
              drop: drop,
              ink: ink,
              heroTag: widget.heroTag,
              height: widget.height,
            ),
            _CloseUpSlide(drop: drop, ink: ink),
            _TypeSlide(drop: drop, ink: ink, now: widget.now),
          ];

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          StudioBackdrop(tone: drop.tone),
          Semantics(
            label: 'Galeria, imagem ${_index + 1} de ${slides.length}',
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _index = i),
              children: slides,
            ),
          ),
          if (slides.length > 1)
            Positioned(
              left: Space.gutter,
              bottom: Space.x5,
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 0; i < slides.length; i++)
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
          Positioned(
            right: Space.x4,
            bottom: Space.x4,
            child: _StatusStamp(
              drop: drop,
              status: widget.status,
              ink: ink,
              now: widget.now,
            ),
          ),
        ],
      ),
    );
  }
}

/// 1ª imagem: o nome em tipografia gigante, o produto e o anel do radar.
class _PosterSlide extends StatelessWidget {
  const _PosterSlide({
    required this.drop,
    required this.ink,
    required this.heroTag,
    required this.height,
  });

  final Drop drop;
  final Color ink;
  final String heroTag;
  final double height;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final wordTop = top + 62;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: wordTop,
          left: 14,
          right: 14,
          child: GiantWord(
            drop.poster,
            color: ink,
            entrance: GiantEntrance.rise,
            delay: const Duration(milliseconds: 140),
            maxHeight: height * 0.25,
            alignment: Alignment.center,
          ),
        ),
        Positioned(
          top: wordTop + height * 0.1,
          left: 14,
          right: 14,
          bottom: 52,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: const Alignment(0, 0.35),
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: 0.46,
                  child: OrbitRing(color: ink),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Hero(
                  tag: heroTag,
                  child: Transform.rotate(
                    angle: drop.art == DropArt.sneaker ? -0.1 : 0,
                    child: DropVisual(drop: drop),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 2ª imagem: o produto de perto, com anotações técnicas.
class _CloseUpSlide extends StatelessWidget {
  const _CloseUpSlide({required this.drop, required this.ink});
  final Drop drop;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    Widget note(String caption, String value, CrossAxisAlignment align) =>
        Column(
          crossAxisAlignment: align,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              caption,
              style: DripType.footnote.copyWith(
                color: ink.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 2),
            Text(value, style: DripType.labelL.copyWith(color: ink)),
          ],
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: Transform.scale(
            scale: 1.85,
            alignment: const Alignment(0.82, 0.3),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, top + 70, 24, 70),
              child: DropVisual(drop: drop, shadow: false),
            ),
          ),
        ),
        Positioned.fill(
          child: ExcludeSemantics(
            child: CustomPaint(painter: _LeaderPainter(ink, top)),
          ),
        ),
        Positioned(
          left: Space.gutter,
          top: top + 66,
          child: note(
            'Cores',
            (drop.colorway ?? drop.category.label).toUpperCase(),
            CrossAxisAlignment.start,
          ),
        ),
        Positioned(
          right: Space.gutter,
          top: top + 110,
          child: note(
            'Categoria',
            drop.category.label.toUpperCase(),
            CrossAxisAlignment.end,
          ),
        ),
      ],
    );
  }
}

/// Linhas de chamada que ligam as anotações ao produto.
class _LeaderPainter extends CustomPainter {
  _LeaderPainter(this.ink, this.top);
  final Color ink;
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ink.withValues(alpha: 0.7);
    final dot = Paint()..color = ink;

    void leader(Offset from, Offset elbow, Offset to) {
      canvas.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo(elbow.dx, elbow.dy)
          ..lineTo(to.dx, to.dy),
        line,
      );
      canvas.drawCircle(to, 2.6, dot);
    }

    final w = size.width, h = size.height;
    leader(
      Offset(22, top + 112),
      Offset(22, h * 0.5),
      Offset(w * 0.34, h * 0.62),
    );
    leader(
      Offset(w - 22, top + 156),
      Offset(w - 22, h * 0.44),
      Offset(w * 0.68, h * 0.54),
    );
  }

  @override
  bool shouldRepaint(_LeaderPainter old) => old.ink != ink || old.top != top;
}

/// 3ª imagem: pôster tipográfico com marca, nome e data.
class _TypeSlide extends StatelessWidget {
  const _TypeSlide({required this.drop, required this.ink, required this.now});
  final Drop drop;
  final Color ink;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 64, 16, 64),
      child: LayoutBuilder(
        builder: (context, box) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GiantWord(
              drop.brandName,
              color: ink,
              maxHeight: box.maxHeight * 0.34,
            ),
            const SizedBox(height: Space.x2),
            GiantWord(
              drop.poster,
              color: ink,
              halftone: true,
              maxHeight: box.maxHeight * 0.34,
            ),
            const SizedBox(height: Space.x4),
            Text(
              drop.whenLine(now).toUpperCase(),
              style: DripType.labelL.copyWith(color: ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// O selo do drop: o status na borda e, no centro, o que mais importa agora
/// (a contagem regressiva, quando há data).
class _StatusStamp extends StatelessWidget {
  const _StatusStamp({
    required this.drop,
    required this.status,
    required this.ink,
    required this.now,
  });

  final Drop drop;
  final DropStatus status;
  final Color ink;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    const size = 116.0;
    final at = drop.releaseAt;
    final fill = ink.computeLuminance() > 0.5
        ? const Color(0xB80A0A0B)
        : const Color(0xC7F3F3F1);
    final big = DripType.dataL.copyWith(color: ink, fontSize: 25);
    final small = DripType.label.copyWith(color: ink, fontSize: 9.5);

    late final String ring;
    late final String spoken;
    late final Widget center;

    switch (status) {
      case DropStatus.upcoming:
        ring =
            'Abre ${Fmt.dayMonth(at!)}${drop.hasTime ? ' ${Fmt.time(at)}' : ''}';
        spoken = 'Abre ${Fmt.untilText(at, now)}';
        center = CountdownBuilder(
          target: at,
          builder: (context, left) {
            final t = Fmt.countdown(left);
            final (String value, String unit) = left.inDays > 0
                ? ('${left.inDays}', left.inDays == 1 ? 'DIA' : 'DIAS')
                : left.inHours > 0
                ? ('${t.h}:${t.m}', 'HORAS')
                : ('${t.m}:${t.s}', 'MINUTOS');
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RollingText(value, style: big),
                const SizedBox(height: 2),
                Text(unit, style: small),
              ],
            );
          },
        );
      case DropStatus.live:
        ring = 'Ao vivo agora';
        spoken = 'Ao vivo agora';
        center = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulseDot(color: ink, size: 9),
            Text('ABERTO', style: small.copyWith(fontSize: 11)),
          ],
        );
      case DropStatus.released:
        ring = 'Lançado ${Fmt.dayMonth(at!)}';
        spoken = 'Lançado em ${Fmt.spokenDate(at)}';
        center = DripIcon(DripGlyph.check, size: 30, color: ink, stroke: 2);
      case DropStatus.tbd:
        ring = 'Data a definir';
        spoken = 'Data a definir';
        center = Text(
          'EM\nBREVE',
          textAlign: TextAlign.center,
          style: small.copyWith(fontSize: 11),
        );
    }

    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: MediaQuery.withNoTextScaling(
        child: CircularStamp(
          text: ring,
          size: size,
          color: ink,
          fill: fill,
          child: center,
        ),
      ),
    );
  }
}
