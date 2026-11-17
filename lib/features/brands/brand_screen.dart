import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/components/buttons.dart';
import '../../core/components/drip_icon.dart';
import '../../core/components/drop_visual.dart';
import '../../core/components/loading.dart';
import '../../core/components/states.dart';
import '../../core/components/surfaces.dart';
import '../../core/components/wordmark.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/links.dart';
import '../../data/models/drop.dart';
import '../../data/providers.dart';
import '../drops/widgets/drop_tiles.dart';
import 'widgets/brand_widgets.dart';

/// Perfil de uma marca: quem é, o site oficial, acompanhar e os lançamentos.
class BrandScreen extends ConsumerStatefulWidget {
  const BrandScreen({super.key, required this.brandId});

  final String brandId;

  @override
  ConsumerState<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends ConsumerState<BrandScreen> {
  static const _barHeight = 52.0;

  final _scroll = ScrollController();
  final _bar = ValueNotifier<double>(0);
  double _coverH = 300;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final top = MediaQuery.paddingOf(context).top;
      final start = _coverH - top - _barHeight - 24;
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
    final brand = ref.watch(brandByIdProvider(widget.brandId));

    if (brand == null) {
      final catalog = ref.watch(brandsProvider);
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
                          glyph: DripGlyph.tag,
                          title: 'Marca não encontrada',
                          message:
                              'Esta marca pode ter saído do catálogo ou o '
                              'link está incompleto.',
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
    final drops = ref.watch(dropsOfBrandProvider(brand.id));
    final open = drops
        .where((d) => d.statusAt(now) != DropStatus.released)
        .toList();
    final past = drops
        .where((d) => d.statusAt(now) == DropStatus.released)
        .toList();
    final uri = Links.parse(brand.websiteUrl);
    final ink = StudioBackdrop.inkOn(brand.tone);
    final cover = brand.coverUrl;
    _coverH = (size.height * 0.36).clamp(240.0, 380.0);

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _coverH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      StudioBackdrop(tone: brand.tone),
                      if (cover != null)
                        CachedNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                        ),
                      if (cover == null)
                        Positioned(
                          left: Space.x4,
                          right: Space.x4,
                          bottom: Space.x5,
                          child: GiantWord(
                            brand.name,
                            color: ink,
                            entrance: GiantEntrance.rise,
                            maxHeight: _coverH * 0.4,
                          ),
                        ),
                    ],
                  ),
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
                      Row(
                        children: [
                          BrandMonogram(brand: brand, size: 56),
                          const SizedBox(width: Space.x3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    brand.name,
                                    style: DripType.title.copyWith(
                                      color: c.text,
                                    ),
                                  ),
                                ),
                                if (brand.origin != null)
                                  Text(
                                    brand.origin!,
                                    style: DripType.caption.copyWith(
                                      color: c.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.x5),
                      Text(
                        brand.tagline,
                        style: DripType.headline.copyWith(color: c.text),
                      ),
                      const SizedBox(height: Space.x2),
                      Text(
                        brand.description,
                        style: DripType.bodyL.copyWith(color: c.text),
                      ),
                      const SizedBox(height: Space.x6),
                      FollowButton(brand: brand, expand: true),
                      const SizedBox(height: Space.x2),
                      DripButton(
                        label: uri == null
                            ? 'Site oficial indisponível'
                            : 'Site oficial · ${Links.host(uri)}',
                        kind: DripButtonKind.secondary,
                        trailing: uri == null ? null : DripGlyph.arrowUpRight,
                        onTap: uri == null ? null : () => _openSite(uri),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: Space.x8)),
              SliverToBoxAdapter(
                child: SectionTitle('Próximos drops', count: open.length),
              ),
              if (open.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'Nada anunciado por enquanto',
                    message:
                        'Acompanhe ${brand.name} para ver o próximo drop em '
                        'Atividade assim que for cadastrado.',
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      0,
                      Space.gutter,
                      Space.x4,
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: open.length,
                  itemBuilder: (_, i) => DropRow(drop: open[i], slot: 'brand'),
                ),
              if (past.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: Space.x6)),
                SliverToBoxAdapter(
                  child: SectionTitle('Já lançados', count: past.length),
                ),
                SliverList.builder(
                  itemCount: past.length,
                  itemBuilder: (_, i) => DropRow(drop: past[i], slot: 'brand'),
                ),
              ],
              SliverToBoxAdapter(
                child: SizedBox(height: insets.bottom + Space.x10),
              ),
            ],
          ),
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
                                  brand.name,
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
                      ],
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
