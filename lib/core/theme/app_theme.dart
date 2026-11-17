import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'tokens.dart';
import 'typography.dart';

export 'tokens.dart';
export 'typography.dart';

extension DripThemeX on BuildContext {
  /// Paleta do DRIP para o tema atual.
  DripColors get c => Theme.of(this).extension<DripColors>()!;

  /// `true` quando o sistema pede menos movimento.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

/// Tema central. Trocar a identidade do app = trocar tokens + este arquivo.
///
/// As transições entre páginas ficam com o padrão de cada plataforma
/// (voltar preditivo no Android, deslizar da borda no iOS): é o que as
/// pessoas já têm na memória muscular.
abstract final class AppTheme {
  static ThemeData dark() => _build(DripColors.dark, Brightness.dark);
  static ThemeData light() => _build(DripColors.light, Brightness.light);

  static ThemeData _build(DripColors c, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.silver,
          brightness: brightness,
        ).copyWith(
          surface: c.bg,
          onSurface: c.text,
          primary: c.accent,
          onPrimary: c.onAccent,
          secondary: c.silver,
          error: c.danger,
          outline: c.line,
          surfaceContainerHigh: c.surfaceHigh,
          surfaceContainer: c.surface,
        );

    // Campo no estilo iOS: cantos arredondados, fundo suave e só um fio de
    // contorno em repouso (o contorno forte aparece no foco).
    final field = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: c.line.withValues(alpha: 0.55)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      fontFamily: DripType.family,
      extensions: [c],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: TextTheme(
        bodyMedium: DripType.body.copyWith(color: c.text),
        bodyLarge: DripType.bodyL.copyWith(color: c.text),
        titleMedium: DripType.subhead.copyWith(color: c.text),
        titleLarge: DripType.title.copyWith(color: c.text),
        labelLarge: DripType.button.copyWith(color: c.text),
      ),
      iconTheme: IconThemeData(color: c.text),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.silver,
        selectionColor: c.silver.withValues(alpha: 0.32),
        selectionHandleColor: c.silver,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: 18,
        ),
        hintStyle: DripType.bodyL.copyWith(color: c.textFaint),
        errorStyle: DripType.caption.copyWith(color: c.danger),
        border: field,
        enabledBorder: field,
        disabledBorder: field,
        focusedBorder: field.copyWith(
          borderSide: BorderSide(color: c.text, width: 1.4),
        ),
        errorBorder: field.copyWith(borderSide: BorderSide(color: c.danger)),
        focusedErrorBorder: field.copyWith(
          borderSide: BorderSide(color: c.danger, width: 1.4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: DripType.headline.copyWith(color: c.text),
        contentTextStyle: DripType.body.copyWith(color: c.textMuted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onAccent : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.surfaceHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.line,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.text,
          textStyle: DripType.button,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
    );
  }
}
