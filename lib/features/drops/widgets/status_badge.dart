import 'package:material_ui/material_ui.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/drop.dart';

/// Status de um drop: uma marca gráfica + a palavra.
/// O estado nunca depende só de cor (cada um tem forma própria).
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.ink});

  final DropStatus status;

  /// Força uma cor única (para usar sobre imagens).
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color =
        ink ??
        switch (status) {
          DropStatus.live => c.live,
          DropStatus.upcoming => c.text,
          DropStatus.released || DropStatus.tbd => c.textMuted,
        };

    final Widget mark = switch (status) {
      DropStatus.live => PulseDot(color: color, size: 7),
      DropStatus.upcoming => _Dot(color: color, filled: true),
      DropStatus.released => _Dot(color: color, filled: true, square: true),
      DropStatus.tbd => _Dot(color: color, filled: false),
    };

    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 17, height: 17, child: Center(child: mark)),
          const SizedBox(width: 4),
          Text(
            status.label.toUpperCase(),
            style: DripType.label.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.filled, this.square = false});
  final Color color;
  final bool filled;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: filled ? color : null,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        border: filled ? null : Border.all(color: color, width: 1.4),
      ),
    );
  }
}
