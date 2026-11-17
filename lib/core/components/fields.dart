import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';
import 'drip_icon.dart';
import 'liquid_glass.dart';
import 'password_strength.dart';

/// Campo de formulário com rótulo fixo acima (o rótulo nunca some ao digitar).
class DripField extends StatefulWidget {
  const DripField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscure = false,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.helper,
    this.maxLength,
    this.showStrength = false,
  });

  /// Mostra o medidor de força e o checklist abaixo do campo (cadastro).
  final bool showStrength;

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscure;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final int? maxLength;

  @override
  State<DripField> createState() => _DripFieldState();
}

class _DripFieldState extends State<DripField> {
  late bool _hidden = widget.obscure;

  /// Só existe quando o medidor de força está ligado: abre o checklist
  /// enquanto o campo está em foco.
  FocusNode? _focus;

  @override
  void initState() {
    super.initState();
    if (widget.showStrength) {
      _focus = FocusNode()..addListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    if (widget.showStrength) widget.controller.removeListener(_refresh);
    _focus?.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(left: 2, bottom: Space.x2),
            child: Text(
              widget.label,
              style: DripType.caption.copyWith(color: c.textMuted),
            ),
          ),
        ),
        // O rótulo visível fica acima; aqui ele é repassado ao leitor de tela.
        Semantics(
          label: widget.label,
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            validator: widget.validator,
            obscureText: _hidden,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            textCapitalization: widget.textCapitalization,
            onFieldSubmitted: widget.onSubmitted,
            autocorrect: !widget.obscure,
            enableSuggestions: !widget.obscure,
            inputFormatters: [
              if (widget.maxLength != null)
                LengthLimitingTextInputFormatter(widget.maxLength),
            ],
            style: DripType.bodyL.copyWith(color: c.text),
            cursorColor: c.silver,
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helper,
              helperStyle: DripType.caption.copyWith(color: c.textFaint),
              helperMaxLines: 2,
              errorMaxLines: 2,
              suffixIcon: widget.obscure
                  ? Pressable(
                      onTap: () => setState(() => _hidden = !_hidden),
                      semanticLabel: _hidden
                          ? 'Mostrar senha'
                          : 'Ocultar senha',
                      focusRadius: Radii.pill,
                      child: Center(
                        widthFactor: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: AnimatedSwitcher(
                            duration: context.reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, a) => FadeTransition(
                              opacity: a,
                              child: ScaleTransition(
                                scale: Tween(begin: 0.6, end: 1.0).animate(a),
                                child: child,
                              ),
                            ),
                            child: DripIcon(
                              _hidden ? DripGlyph.eye : DripGlyph.eyeOff,
                              key: ValueKey(_hidden),
                              size: 20,
                              color: c.textMuted,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        if (widget.showStrength)
          PasswordStrengthMeter(
            password: widget.controller.text,
            expanded: _focus?.hasFocus ?? false,
          ),
      ],
    );
  }
}

/// Campo de busca com botão de limpar.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Buscar',
    this.focusNode,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final FocusNode? focusNode;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasText = widget.controller.text.isNotEmpty;
    final none = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: c.line.withValues(alpha: 0.4)),
    );
    // Campo de vidro: a lista que rola por baixo curva na borda.
    return LiquidGlassContainer(
      borderRadius: BorderRadius.circular(Radii.md),
      blurSigma: 6,
      tint: c.surface.withValues(alpha: 0.75),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        style: DripType.bodyL.copyWith(color: c.text),
        cursorColor: c.silver,
        decoration: InputDecoration(
          hintText: widget.hint,
          filled: false,
          border: none,
          enabledBorder: none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          prefixIcon: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: Space.x4, right: Space.x3),
              child: DripIcon(DripGlyph.search, size: 20, color: c.textMuted),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minHeight: 44),
          suffixIcon: AnimatedSwitcher(
            duration: Motion.fast,
            child: hasText
                ? Pressable(
                    key: const ValueKey('clear'),
                    onTap: () {
                      widget.controller.clear();
                      widget.onChanged('');
                    },
                    semanticLabel: 'Limpar busca',
                    focusRadius: Radii.pill,
                    child: Center(
                      widthFactor: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: DripIcon(
                          DripGlyph.close,
                          size: 18,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('none'), width: 12),
          ),
        ),
      ),
    );
  }
}
