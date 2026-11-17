import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/components/buttons.dart';
import '../../core/components/drip_icon.dart';
import '../../core/components/states.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/user.dart';
import '../../data/providers.dart';
import '../shell/tab_page.dart';
import 'activity_logic.dart';

/// Atividade: avisos sobre drops salvos e marcas acompanhadas,
/// com estado de lido / não lido.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final items = ref.watch(activityProvider);
    final unread = items.where((i) => !i.read).toList();
    final now = ref.watch(nowProvider);
    final demo = !ref.watch(firebaseReadyProvider);

    void open(ActivityItem item) {
      if (!item.read) ref.read(userActionsProvider).markRead([item.id]);
      final dropId = item.dropId;
      final brandId = item.brandId;
      if (dropId != null) {
        context.push(Routes.drop(dropId));
      } else if (brandId != null) {
        context.push(Routes.brand(brandId));
      }
    }

    return TabPage(
      tabIndex: 3,
      title: 'Atividade',
      count: unread.length,
      actions: [
        if (unread.isNotEmpty)
          DripButton(
            label: 'Marcar como lidas',
            semanticLabel: 'Marcar todas as atividades como lidas',
            kind: DripButtonKind.ghost,
            foreground: c.text,
            expand: false,
            compact: true,
            onTap: () =>
                ref.read(userActionsProvider).markRead(unread.map((i) => i.id)),
          ),
      ],
      slivers: [
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              glyph: DripGlyph.bell,
              title: 'Tudo calmo por aqui',
              message:
                  'Salve drops e acompanhe marcas: os avisos de abertura e '
                  'os novos lançamentos aparecem nesta tela.',
              actionLabel: 'Ver próximos drops',
              onAction: () => context.go(Routes.discover),
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                0,
                Space.gutter,
                Space.x6,
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => _ActivityRow(
              item: items[i],
              now: now,
              onTap: () => open(items[i]),
            ),
          ),
        if (demo)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.x6,
                Space.gutter,
                0,
              ),
              child: Text(
                'Estes avisos são calculados neste aparelho, a partir do que '
                'você salvou. As notificações push dependem do servidor '
                '(Firebase), que ainda não está configurado.',
                style: DripType.footnote.copyWith(color: c.textFaint),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.item,
    required this.now,
    required this.onTap,
  });

  final ActivityItem item;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final glyph = switch (item.kind) {
      ActivityKind.live => DripGlyph.radar,
      ActivityKind.soon => DripGlyph.clock,
      ActivityKind.brandDrop => DripGlyph.tag,
      ActivityKind.system => DripGlyph.info,
    };
    final when = Fmt.sinceText(item.at, now);
    return Pressable(
      onTap: onTap,
      scale: 0.985,
      semanticLabel:
          '${item.read ? '' : 'Não lida. '}${item.title}. ${item.body} $when',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.x2,
          Space.x3,
          Space.gutter,
          Space.x3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Marca de não lida: forma + cor (não depende só da cor).
            SizedBox(
              width: 12,
              height: 22,
              child: Center(
                child: AnimatedOpacity(
                  opacity: item.read ? 0 : 1,
                  duration: Motion.base,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: c.live,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            DripIcon(
              glyph,
              size: 22,
              color: item.kind == ActivityKind.live && !item.read
                  ? c.live
                  : (item.read ? c.textFaint : c.text),
            ),
            const SizedBox(width: Space.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: DripType.subhead.copyWith(
                      color: item.read ? c.textMuted : c.text,
                      fontVariations: [
                        FontVariation('wght', item.read ? 480 : 620),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    style: DripType.caption.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    when,
                    style: DripType.footnote.copyWith(color: c.textFaint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
