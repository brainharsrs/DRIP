import 'package:material_ui/material_ui.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';
import '../utils/password_strength.dart';
import 'drip_icon.dart';

/// Cores dos níveis de força: cinza, vermelho, laranja, amarelo, esmeralda.
/// O tema claro usa versões mais escuras para manter a leitura.
List<Color> _levelColors(BuildContext context) {
  final c = context.c;
  final dark = Theme.of(context).brightness == Brightness.dark;
  return dark
      ? [
          c.line,
          const Color(0xFFFF6B5E),
          const Color(0xFFFF9F45),
          const Color(0xFFF5D04A),
          const Color(0xFF34D399),
        ]
      : [
          c.line,
          const Color(0xFFC0392B),
          const Color(0xFFC9660A),
          const Color(0xFFA88700),
          const Color(0xFF0E9F6E),
        ];
}

/// Medidor de força da senha: 4 barrinhas, texto de status e um checklist
/// de requisitos que só fica aberto enquanto [expanded] for `true`
/// (campo em foco).
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({
    super.key,
    required this.password,
    required this.expanded,
  });

  final String password;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final colors = _levelColors(context);
    final score = PasswordStrength.score(password);
    final met = PasswordStrength.met(password);
    final color = colors[score];
    final duration = context.reduceMotion ? Duration.zero : Motion.base;

    return Padding(
      padding: const EdgeInsets.only(top: Space.x3, left: 2, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            label: score == 0
                ? 'Senha: use ${PasswordStrength.label(0).toLowerCase()}'
                : 'Força da senha: ${PasswordStrength.label(score)}',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < PasswordStrength.maxScore; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: AnimatedContainer(
                            duration: duration,
                            curve: Curves.easeOutCubic,
                            height: 4,
                            decoration: BoxDecoration(
                              color: i < score ? color : colors[0],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Space.x2),
                  AnimatedSwitcher(
                    duration: context.reduceMotion
                        ? Duration.zero
                        : Motion.base,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...previous, ?current],
                    ),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.35),
                          end: Offset.zero,
                        ).animate(a),
                        child: child,
                      ),
                    ),
                    child: Text(
                      PasswordStrength.label(score),
                      key: ValueKey(score),
                      style: DripType.caption.copyWith(
                        color: score == 0 ? c.textFaint : color,
                        fontWeight: score == 0 ? null : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SoftSize(
            alignment: Alignment.topLeft,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: Space.x3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final rule in PasswordRule.values)
                          _RuleRow(
                            label: rule.label,
                            met: met.contains(rule),
                            color: colors[4],
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Uma linha do checklist. O ícone dá um "pop" elástico quando o requisito
/// passa a ser atendido.
class _RuleRow extends StatefulWidget {
  const _RuleRow({required this.label, required this.met, required this.color});

  final String label;
  final bool met;
  final Color color;

  @override
  State<_RuleRow> createState() => _RuleRowState();
}

class _RuleRowState extends State<_RuleRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
    value: 1,
  );
  late final Animation<double> _scale = Tween(
    begin: 0.35,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _pop, curve: Curves.elasticOut));

  @override
  void didUpdateWidget(_RuleRow old) {
    super.didUpdateWidget(old);
    if (widget.met && !old.met && !context.reduceMotion) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final met = widget.met;
    final duration = context.reduceMotion ? Duration.zero : Motion.base;
    return Semantics(
      label: '${widget.label}: ${met ? 'atendido' : 'pendente'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              ScaleTransition(
                scale: _scale,
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: met ? widget.color : Colors.transparent,
                    border: Border.all(
                      color: met ? widget.color : c.textFaint,
                      width: 1.4,
                    ),
                  ),
                  child: AnimatedOpacity(
                    duration: duration,
                    opacity: met ? 1 : 0,
                    child: DripIcon(
                      DripGlyph.check,
                      size: 12,
                      color: c.bg,
                      stroke: 2.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.x3),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  style: DripType.footnote.copyWith(
                    color: met ? c.text : c.textMuted,
                  ),
                  child: Text(widget.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
