import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/components/buttons.dart';
import '../../../core/components/surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/drop.dart';
import '../../../data/providers.dart';
import 'want_list_slingshot.dart';

/// Folha "Salvar na Want List" com o estilingue.
///
/// O lançamento chama o mesmo salvar de sempre (`UserActions.setWant`).
/// Quem não pode ou não quer arrastar tem o botão "Salvar sem lançar".
Future<void> showWantListSlingshot(BuildContext context, Drop drop) =>
    showDripSheet<void>(
      context: context,
      title: 'Salvar na Want List',
      builder: (_) => _SlingshotSheet(drop: drop),
    );

class _SlingshotSheet extends ConsumerStatefulWidget {
  const _SlingshotSheet({required this.drop});

  final Drop drop;

  @override
  ConsumerState<_SlingshotSheet> createState() => _SlingshotSheetState();
}

class _SlingshotSheetState extends ConsumerState<_SlingshotSheet> {
  bool _saved = false;

  Future<void> _save() async {
    if (_saved) return;
    _saved = true;
    try {
      await ref.read(userActionsProvider).setWant(widget.drop.id, true);
    } catch (_) {
      _saved = false;
      if (mounted) {
        showToast(context, 'Não deu para salvar agora. Tente de novo.');
      }
    }
  }

  void _close() {
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Puxe a bolinha para baixo e solte para lançar '
          '${widget.drop.name} na sua Want List.',
          style: DripType.body.copyWith(color: c.textMuted),
        ),
        WantListSlingshot(
          semanticLabel: 'Lançar ${widget.drop.name} na Want List',
          onAddedToWantList: _save,
          onCycleComplete: _close,
        ),
        DripButton(
          label: 'Salvar sem lançar',
          kind: DripButtonKind.secondary,
          onTap: () async {
            await _save();
            if (_saved) _close();
          },
        ),
      ],
    );
  }
}
