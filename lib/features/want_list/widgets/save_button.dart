import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/components/drip_icon.dart';
import '../../../core/components/surfaces.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/drop.dart';
import '../../../data/providers.dart';
import 'want_list_slingshot_sheet.dart';

enum SaveStyle {
  /// Só o ícone.
  plain,

  /// Círculo translúcido, para usar sobre imagens.
  glass,

  /// Círculo com contorno.
  outline,
}

/// Salva ou remove um drop da Want List.
/// Ao salvar, o marcador preenche e dá um leve "pulo" de confirmação.
class SaveButton extends ConsumerWidget {
  const SaveButton({
    super.key,
    required this.drop,
    this.style = SaveStyle.plain,
    this.ink,
    this.size = 44,
    this.slingshot = false,
  });

  /// Ao salvar, abre o estilingue em vez de salvar direto. Remover continua
  /// sendo um toque só.
  final bool slingshot;

  final Drop drop;
  final SaveStyle style;
  final Color? ink;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final saved = ref.watch(userDataProvider.select((d) => d.wants(drop.id)));
    final color = ink ?? (saved ? c.text : c.textMuted);

    Widget body = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: switch (style) {
        SaveStyle.plain || SaveStyle.glass => null,
        SaveStyle.outline => BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.line),
        ),
      },
      child: _Bookmark(saved: saved, color: color, size: size * 0.5),
    );
    if (style == SaveStyle.glass) {
      // Gota de vidro líquido sobre a arte do produto.
      body = LiquidGlassContainer(
        borderRadius: BorderRadius.circular(size / 2),
        blurSigma: 6,
        bendIntensity: 1.3,
        tint: (ink ?? c.text).computeLuminance() > 0.5
            ? const Color(0x47000000)
            : const Color(0x66FFFFFF),
        tintStrength: 0.75,
        child: body,
      );
    }

    return Pressable(
      onTap: () async {
        HapticFeedback.lightImpact();
        if (slingshot && !saved) {
          await showWantListSlingshot(context, drop);
          return;
        }
        try {
          await ref.read(userActionsProvider).toggleWant(drop.id);
        } catch (_) {
          if (context.mounted) {
            showToast(context, 'Não deu para salvar agora. Tente de novo.');
          }
        }
      },
      selected: saved,
      scale: 0.88,
      focusRadius: Radii.pill,
      semanticLabel: saved
          ? 'Remover ${drop.name} da Want List'
          : 'Salvar ${drop.name} na Want List',
      child: body,
    );
  }
}

class _Bookmark extends StatefulWidget {
  const _Bookmark({
    required this.saved,
    required this.color,
    required this.size,
  });

  final bool saved;
  final Color color;
  final double size;

  @override
  State<_Bookmark> createState() => _BookmarkState();
}

class _BookmarkState extends State<_Bookmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(_Bookmark old) {
    super.didUpdateWidget(old);
    if (!old.saved && widget.saved && !context.reduceMotion) {
      // Parte de menor e passa um pouco do tamanho final: confirmação tátil.
      _c.animateWith(SpringSimulation(kPopSpring, 0.62, 1, 0));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _c,
      child: DripIcon(
        widget.saved ? DripGlyph.bookmarkFilled : DripGlyph.bookmark,
        size: widget.size,
        color: widget.color,
        stroke: 1.7,
      ),
    );
  }
}
