import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/components/surfaces.dart';
import '../../core/theme/app_theme.dart';
import 'app_shell.dart';

/// Estrutura das abas de trabalho (Explorar, Want List, Atividade, Perfil).
///
/// O título grande faz parte do conteúdo e, ao rolar, encolhe para a barra
/// do topo, que ganha o material translúcido. Tocar de novo no ícone da aba
/// volta ao topo.
class TabPage extends ConsumerStatefulWidget {
  const TabPage({
    super.key,
    required this.tabIndex,
    required this.title,
    required this.slivers,
    this.count,
    this.actions = const [],
    this.pinned,
    this.pinnedHeight = 0,
    this.largeTitle = true,
  });

  final int tabIndex;
  final String title;
  final int? count;
  final List<Widget> slivers;

  /// Botões à direita da barra.
  final List<Widget> actions;

  /// Conteúdo fixo sob a barra (ex.: campo de busca).
  final Widget? pinned;
  final double pinnedHeight;
  final bool largeTitle;

  static const barHeight = 52.0;

  @override
  ConsumerState<TabPage> createState() => _TabPageState();
}

class _TabPageState extends ConsumerState<TabPage> {
  final _scroll = ScrollController();
  final _collapse = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scroll.offset;
    _collapse.value = widget.largeTitle
        ? ((offset - 26) / 20).clamp(0.0, 1.0)
        : (offset / 12).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _collapse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final insets = MediaQuery.paddingOf(context);
    final barH = insets.top + TabPage.barHeight + widget.pinnedHeight;

    ref.listen(tabReselectProvider, (_, next) {
      if (next.index == widget.tabIndex && _scroll.hasClients) {
        _scroll.animateTo(0, duration: Motion.slow, curve: Motion.out);
      }
    });

    return ColoredBox(
      color: c.bg,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: barH)),
              if (widget.largeTitle)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      Space.x1,
                      Space.gutter,
                      Space.x5,
                    ),
                    child: _TitleWithCount(
                      title: widget.title,
                      count: widget.count,
                      style: DripType.largeTitle.copyWith(color: c.text),
                      header: true,
                    ),
                  ),
                ),
              ...widget.slivers,
              SliverToBoxAdapter(
                child: SizedBox(height: insets.bottom + Space.x10),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: barH,
            child: ValueListenableBuilder<double>(
              valueListenable: _collapse,
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
                    padding: EdgeInsets.only(top: insets.top),
                    child: Column(
                      children: [
                        SizedBox(
                          height: TabPage.barHeight,
                          child: Row(
                            children: [
                              const SizedBox(width: Space.gutter),
                              Expanded(
                                child: Opacity(
                                  opacity: widget.largeTitle ? t : 1,
                                  child: ExcludeSemantics(
                                    // O título grande já é o cabeçalho lido.
                                    excluding: widget.largeTitle,
                                    child: _TitleWithCount(
                                      title: widget.title,
                                      count: widget.largeTitle
                                          ? null
                                          : widget.count,
                                      style:
                                          (widget.largeTitle
                                                  ? DripType.subhead
                                                  : DripType.title)
                                              .copyWith(color: c.text),
                                      header: !widget.largeTitle,
                                    ),
                                  ),
                                ),
                              ),
                              ...widget.actions,
                              const SizedBox(width: Space.x2),
                            ],
                          ),
                        ),
                        if (widget.pinned != null)
                          SizedBox(
                            height: widget.pinnedHeight,
                            child: widget.pinned,
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

class _TitleWithCount extends StatelessWidget {
  const _TitleWithCount({
    required this.title,
    required this.style,
    required this.header,
    this.count,
  });

  final String title;
  final int? count;
  final TextStyle style;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final n = count;
    return Semantics(
      header: header,
      label: n == null ? title : '$title, $n',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          if (n != null && n > 0)
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 3),
              child: Text(
                '$n',
                style: DripType.labelL.copyWith(color: context.c.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
