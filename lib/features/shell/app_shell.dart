import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/components/drip_icon.dart';
import '../../core/components/liquid_glass.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../activity/activity_logic.dart';

/// Avisa a aba ativa quando seu ícone é tocado de novo (para rolar ao topo).
class TabReselect extends Notifier<({int index, int tick})> {
  @override
  ({int index, int tick}) build() => (index: -1, tick: 0);

  void ping(int index) => state = (index: index, tick: state.tick + 1);
}

final tabReselectProvider =
    NotifierProvider<TabReselect, ({int index, int tick})>(TabReselect.new);

/// Moldura das cinco abas principais: conteúdo + barra de abas translúcida.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = navigationShell.currentIndex;
    return PopScope(
      // Voltar numa aba secundária leva ao Discover antes de sair do app.
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: DripTabBar(
          index: index,
          unread: ref.watch(unreadCountProvider),
          onSelect: (i) {
            if (i == index) {
              ref.read(tabReselectProvider.notifier).ping(i);
            } else {
              navigationShell.goBranch(i);
            }
          },
        ),
      ),
    );
  }
}

/// Troca de aba com um fade curto, mantendo o estado de todas.
class BranchSwitcher extends StatelessWidget {
  const BranchSwitcher({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: ExcludeFocus(
              excluding: i != index,
              child: ExcludeSemantics(
                excluding: i != index,
                // O fade fica FORA do TickerMode: se ficasse dentro, a aba
                // que sai teria o relógio desligado antes de sumir e
                // continuaria opaca por cima das outras.
                child: AnimatedOpacity(
                  key: ValueKey('branch-$i'),
                  opacity: i == index ? 1 : 0,
                  duration: Motion.base,
                  curve: Motion.out,
                  child: TickerMode(enabled: i == index, child: children[i]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Tab {
  const _Tab(this.label, this.glyph, [this.activeGlyph]);
  final String label;
  final DripGlyph glyph;
  final DripGlyph? activeGlyph;
}

const _tabs = [
  _Tab('Descobrir', DripGlyph.radar),
  _Tab('Explorar', DripGlyph.search),
  _Tab('Want List', DripGlyph.bookmark, DripGlyph.bookmarkFilled),
  _Tab('Atividade', DripGlyph.bell),
  _Tab('Perfil', DripGlyph.user),
];

/// Barra de abas flutuante, em pílula de vidro: fica um pouco acima da borda
/// inferior (respeitando a área segura) e o conteúdo rola por baixo dela.
/// Uma pílula interna desliza até a aba ativa.
class DripTabBar extends StatelessWidget {
  const DripTabBar({
    super.key,
    required this.index,
    required this.onSelect,
    this.unread = 0,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final int unread;

  /// Altura da pílula.
  static const height = 64.0;

  /// Distância até a borda inferior (somada à área segura) e até as laterais.
  static const _gap = 10.0;
  static const _side = 16.0;

  /// Folga entre a borda da pílula e a pílula de destaque.
  static const _inset = 5.0;

  static const _radius = BorderRadius.all(Radius.circular(50));

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final solid = MediaQuery.highContrastOf(context);
    final safe = MediaQuery.paddingOf(context).bottom;
    const white = Color(0xFFFFFFFF);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Padding(
        padding: EdgeInsets.fromLTRB(_side, 0, _side, safe + _gap),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            // Vidro líquido: refração na borda, brilho especular e sombra.
            child: LiquidGlassContainer(
              borderRadius: _radius,
              blurSigma: 6,
              tint: c.glass.withValues(alpha: 0.6),
              shadow: true,
              child: DecoratedBox(
                // Fio de 1px que separa a pílula do conteúdo.
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: _radius,
                  border: Border.all(
                    color: solid
                        ? c.line
                        : white.withValues(alpha: dark ? 0.08 : 0.4),
                  ),
                ),
                child: SizedBox(
                  height: height,
                  child: Padding(
                    padding: const EdgeInsets.all(_inset),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Pílula de destaque: a "célula" tem a largura
                        // de uma aba e o alinhamento a encaixa sobre a
                        // aba ativa.
                        AnimatedAlign(
                          duration: context.reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 380),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment(
                            -1 + 2 * index / (_tabs.length - 1),
                            0,
                          ),
                          child: FractionallySizedBox(
                            widthFactor: 1 / _tabs.length,
                            heightFactor: 1,
                            // Uma gota de vidro mais grossa dentro do
                            // vidro da barra.
                            child: LiquidGlassContainer(
                              borderRadius: _radius,
                              blurSigma: 0,
                              bendIntensity: 1.4,
                              tint: c.text.withValues(
                                alpha: dark ? 0.12 : 0.08,
                              ),
                              tintStrength: 0.75,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < _tabs.length; i++)
                              Expanded(
                                child: _TabItem(
                                  tab: _tabs[i],
                                  active: i == index,
                                  position: i + 1,
                                  badge: i == 3 ? unread : 0,
                                  onTap: () => onSelect(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.active,
    required this.position,
    required this.badge,
    required this.onTap,
  });

  final _Tab tab;
  final bool active;
  final int position;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = active ? c.text : c.textMuted;
    final news = badge == 0
        ? ''
        : ', $badge ${badge == 1 ? 'aviso novo' : 'avisos novos'}';
    return Pressable(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      selected: active,
      scale: 0.88,
      focusRadius: 50,
      semanticLabel: '${tab.label}, aba $position de ${_tabs.length}$news',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedSwitcher(
                duration: Motion.fast,
                child: DripIcon(
                  active ? (tab.activeGlyph ?? tab.glyph) : tab.glyph,
                  key: ValueKey(active),
                  size: 23,
                  color: color,
                  stroke: active ? 1.9 : 1.5,
                ),
              ),
              if (badge > 0)
                Positioned(
                  right: -3,
                  top: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: c.live,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bg, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            tab.label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: DripType.tab.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
