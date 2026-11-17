import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/components/buttons.dart';
import '../../../core/components/drip_icon.dart';
import '../../../core/components/surfaces.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/brand.dart';
import '../../../data/providers.dart';

/// Acompanhar / deixar de acompanhar uma marca.
class FollowButton extends ConsumerWidget {
  const FollowButton({
    super.key,
    required this.brand,
    this.expand = false,
    this.dense = false,
  });

  final Brand brand;
  final bool expand;

  /// Versão pequena e discreta, para repetir em listas sem competir com o
  /// conteúdo. A versão normal é o botão principal do perfil da marca.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final following = ref.watch(
      userDataProvider.select((d) => d.follows(brand.id)),
    );
    final spoken = following
        ? 'Deixar de acompanhar ${brand.name}'
        : 'Acompanhar ${brand.name}';

    Future<void> toggle() async {
      HapticFeedback.lightImpact();
      try {
        final now = await ref.read(userActionsProvider).toggleFollow(brand.id);
        if (context.mounted && now) {
          showToast(
            context,
            'Você vai ver os novos drops de ${brand.name} em Atividade.',
          );
        }
      } catch (_) {
        if (context.mounted) {
          showToast(context, 'Não deu para atualizar agora. Tente de novo.');
        }
      }
    }

    final animated = context.reduceMotion ? Duration.zero : Motion.base;

    if (dense) {
      final fg = following ? c.textMuted : c.text;
      return Pressable(
        onTap: toggle,
        selected: following,
        semanticLabel: spoken,
        focusRadius: Radii.pill,
        child: Center(
          widthFactor: 1,
          child: SoftSize(
            alignment: Alignment.centerRight,
            child: AnimatedContainer(
              duration: animated,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: following ? Colors.transparent : c.surfaceHigh,
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(color: following ? c.line : c.surfaceHigh),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (following) ...[
                    DripIcon(DripGlyph.check, size: 14, color: fg),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    following ? 'Acompanhando' : 'Acompanhar',
                    style: DripType.caption.copyWith(
                      color: fg,
                      fontVariations: const [FontVariation('wght', 620)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SoftSize(
      alignment: Alignment.centerRight,
      child: DripButton(
        label: following ? 'Acompanhando' : 'Acompanhar',
        semanticLabel: spoken,
        leading: following ? DripGlyph.check : DripGlyph.plus,
        kind: following ? DripButtonKind.secondary : DripButtonKind.primary,
        expand: expand,
        onTap: toggle,
      ),
    );
  }
}

/// Símbolo da marca: o logo, se cadastrado; senão, as iniciais.
class BrandMonogram extends StatelessWidget {
  const BrandMonogram({super.key, required this.brand, this.size = 56});

  final Brand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final initials = Text(
      brand.monogram.toUpperCase(),
      style: DripType.labelL.copyWith(
        color: c.text,
        fontSize: size * 0.3,
        letterSpacing: 0,
      ),
    );
    final logo = brand.logoUrl;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.surfaceHigh,
          border: Border.all(color: c.line),
        ),
        child: logo == null
            ? initials
            : CachedNetworkImage(
                imageUrl: logo,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => initials,
              ),
      ),
    );
  }
}

/// Linha de marca: símbolo, nome, frase e botão de acompanhar.
class BrandRow extends StatelessWidget {
  const BrandRow({super.key, required this.brand, this.showFollow = true});

  final Brand brand;
  final bool showFollow;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 6, Space.gutter, 6),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: () => context.push(Routes.brand(brand.id)),
              scale: 0.985,
              semanticLabel: 'Marca ${brand.name}. ${brand.tagline}',
              child: Row(
                children: [
                  BrandMonogram(brand: brand, size: 52),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DripType.subhead.copyWith(color: c.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          brand.tagline,
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
          if (showFollow) ...[
            const SizedBox(width: Space.x2),
            FollowButton(brand: brand, dense: true),
          ],
        ],
      ),
    );
  }
}

/// Marca em formato compacto, para listas horizontais.
class BrandBubble extends StatelessWidget {
  const BrandBubble({super.key, required this.brand});

  final Brand brand;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.push(Routes.brand(brand.id)),
      semanticLabel: 'Marca ${brand.name}',
      scale: 0.94,
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMonogram(brand: brand, size: 68),
            const SizedBox(height: Space.x2),
            Text(
              brand.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: DripType.footnote.copyWith(color: context.c.text),
            ),
          ],
        ),
      ),
    );
  }
}
