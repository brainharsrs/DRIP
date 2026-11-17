import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'buttons.dart';
import 'drip_icon.dart';

/// Estado vazio: diz o que falta e oferece o próximo passo, no lugar onde
/// o conteúdo vai aparecer. Alinhado à esquerda, como o resto da tela.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.glyph,
    this.padding = const EdgeInsets.symmetric(
      horizontal: Space.gutter,
      vertical: Space.x6,
    ),
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final DripGlyph? glyph;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            DripIcon(glyph!, size: 26, color: c.textMuted),
            const SizedBox(height: Space.x4),
          ],
          Text(title, style: DripType.headline.copyWith(color: c.text)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              message,
              style: DripType.body.copyWith(color: c.textMuted),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: Space.x5),
            DripButton(
              label: actionLabel!,
              onTap: onAction,
              kind: DripButtonKind.secondary,
              expand: false,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Erro dentro do bloco que falhou: o que houve e como tentar de novo.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Não deu para carregar',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      glyph: DripGlyph.info,
      title: title,
      message: message,
      actionLabel: onRetry == null ? null : 'Tentar de novo',
      onAction: onRetry,
    );
  }
}
