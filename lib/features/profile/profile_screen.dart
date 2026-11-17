import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/components/buttons.dart';
import '../../core/components/chips.dart';
import '../../core/components/drip_icon.dart';
import '../../core/components/states.dart';
import '../../core/components/surfaces.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/brand.dart';
import '../../data/models/drop.dart';
import '../../data/providers.dart';
import '../brands/widgets/brand_widgets.dart';
import '../settings/settings_widgets.dart';
import '../shell/tab_page.dart';

/// Perfil: quem é a pessoa, o que ela salvou e segue, seus interesses
/// e os atalhos para configurações e saída.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final user = ref.watch(currentUserProvider);
    final data = ref.watch(userDataProvider);
    final drops = ref.watch(dropsProvider).value ?? const <Drop>[];
    final brands = ref.watch(brandsProvider).value ?? const <Brand>[];
    final following = brands.where((b) => data.follows(b.id)).toList();
    final saved = drops.where((d) => data.wants(d.id)).length;
    final actions = ref.read(userActionsProvider);

    final name = user?.name ?? '';
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    Future<void> signOut() async {
      final ok = await confirmSheet(
        context,
        title: 'Sair da conta?',
        message:
            'Sua Want List e as marcas que você acompanha continuam '
            'guardadas. É só entrar de novo para vê-las.',
        confirmLabel: 'Sair',
      );
      if (ok) await ref.read(authRepositoryProvider).signOut();
    }

    return TabPage(
      tabIndex: 4,
      title: 'Perfil',
      actions: [
        IconPill(
          glyph: DripGlyph.settings,
          label: 'Configurações',
          onTap: () => context.push(Routes.settings),
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              0,
              Space.gutter,
              Space.x5,
            ),
            child: MergeSemantics(
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.surfaceHigh,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.line),
                      ),
                      child: Text(
                        initials.isEmpty ? '?' : initials,
                        style: DripType.labelL.copyWith(
                          color: c.text,
                          fontSize: 17,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.x4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Sua conta' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DripType.headline.copyWith(color: c.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DripType.caption.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Resumo: dois números, um quadro só.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              0,
              Space.gutter,
              Space.x8,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCell(
                        caption: 'Na Want List',
                        value: '$saved',
                        spoken:
                            '$saved ${saved == 1 ? 'drop' : 'drops'} na '
                            'Want List. Abrir',
                        onTap: () => context.go(Routes.wantList),
                      ),
                    ),
                    Container(width: 0.8, color: c.line),
                    Expanded(
                      child: _SummaryCell(
                        caption: 'Marcas acompanhadas',
                        value: '${following.length}',
                        spoken:
                            '${following.length} marcas acompanhadas. '
                            'Explorar marcas',
                        onTap: () => context.go(Routes.explore),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SectionTitle('Interesses')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              0,
              Space.gutter,
              Space.x8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Os destaques do Discover priorizam o que você marcar aqui.',
                  style: DripType.caption.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: Space.x2),
                Wrap(
                  spacing: Space.x2,
                  runSpacing: 2,
                  children: [
                    for (final cat in DropCategory.values)
                      DripChip(
                        label: cat.label,
                        glyph: data.interests.contains(cat.name)
                            ? DripGlyph.check
                            : null,
                        selected: data.interests.contains(cat.name),
                        onTap: () => actions.setInterest(
                          cat.name,
                          !data.interests.contains(cat.name),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SectionTitle(
            'Marcas que você acompanha',
            count: following.length,
          ),
        ),
        if (following.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              title: 'Nenhuma marca ainda',
              message:
                  'Acompanhe uma marca para saber dos novos drops dela '
                  'assim que forem cadastrados.',
              actionLabel: 'Encontrar marcas',
              onAction: () => context.go(Routes.explore),
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
            itemCount: following.length,
            itemBuilder: (_, i) => BrandRow(brand: following[i]),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: Space.x8)),
        SliverToBoxAdapter(
          child: SettingsGroup(
            children: [
              SettingsRow(
                title: 'Configurações',
                subtitle: 'Conta, notificações, aparência e privacidade',
                onTap: () => context.push(Routes.settings),
              ),
              SettingsRow(title: 'Sair', onTap: signOut),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.caption,
    required this.value,
    required this.spoken,
    required this.onTap,
  });

  final String caption;
  final String value;
  final String spoken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: spoken,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x4,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FactCell(caption: caption, value: value),
        ),
      ),
    );
  }
}
