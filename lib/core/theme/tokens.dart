import 'package:material_ui/material_ui.dart';

/// Tokens do Design System do DRIP.
///
/// Tudo o que define a identidade (cor, espaço, raio, tempo) mora aqui.
/// As telas nunca usam valores soltos: trocam-se os tokens, troca-se o app.

/// Paleta semântica. Uma instância para o tema escuro (padrão da marca)
/// e outra para o claro.
@immutable
class DripColors extends ThemeExtension<DripColors> {
  const DripColors({
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.line,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.onAccent,
    required this.silver,
    required this.live,
    required this.danger,
    required this.success,
    required this.scrim,
    required this.glass,
  });

  /// Fundo da tela.
  final Color bg;

  /// Superfície de cartões e campos.
  final Color surface;

  /// Superfície elevada (sheets, itens pressionados).
  final Color surfaceHigh;

  /// Bordas e divisórias finas.
  final Color line;

  final Color text;
  final Color textMuted;

  /// Texto terciário (legendas, horários). Ainda passa de 4,5:1 no fundo.
  final Color textFaint;

  /// Cor de ação principal (botão primário).
  final Color accent;
  final Color onAccent;

  /// Prata da marca: destaques, estados ativos, brilho metálico.
  final Color silver;

  /// "Energia fria": indica drop ao vivo.
  final Color live;
  final Color danger;
  final Color success;
  final Color scrim;

  /// Base translúcida das barras flutuantes.
  final Color glass;

  static const dark = DripColors(
    bg: Color(0xFF0A0A0B),
    surface: Color(0xFF141416),
    surfaceHigh: Color(0xFF1D1D20),
    line: Color(0xFF2B2B2F),
    text: Color(0xFFF3F3F1),
    textMuted: Color(0xFFA0A0A8),
    textFaint: Color(0xFF85858E),
    accent: Color(0xFFF3F3F1),
    onAccent: Color(0xFF0A0A0B),
    silver: Color(0xFFC5C8D6),
    live: Color(0xFFA9E1FF),
    danger: Color(0xFFFF7A6B),
    success: Color(0xFF86E3B0),
    scrim: Color(0xB3000000),
    glass: Color(0xB8101012),
  );

  static const light = DripColors(
    bg: Color(0xFFECEBE6),
    surface: Color(0xFFF5F4F0),
    surfaceHigh: Color(0xFFFFFFFF),
    line: Color(0xFFD5D4CD),
    text: Color(0xFF0A0A0B),
    textMuted: Color(0xFF55555B),
    textFaint: Color(0xFF66666C),
    accent: Color(0xFF0A0A0B),
    onAccent: Color(0xFFF3F3F1),
    silver: Color(0xFF3E4145),
    live: Color(0xFF0B6FA8),
    danger: Color(0xFFC0392B),
    success: Color(0xFF1E8A55),
    scrim: Color(0x80000000),
    glass: Color(0xCCECEBE6),
  );

  @override
  DripColors copyWith() => this;

  @override
  DripColors lerp(DripColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DripColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      line: l(line, other.line),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      silver: l(silver, other.silver),
      live: l(live, other.live),
      danger: l(danger, other.danger),
      success: l(success, other.success),
      scrim: l(scrim, other.scrim),
      glass: l(glass, other.glass),
    );
  }
}

/// Escala de espaçamento (base 4).
abstract final class Space {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;

  /// Margem lateral padrão das telas.
  static const double gutter = 20;

  /// Altura reservada para a barra de navegação flutuante.
  static const double navClearance = 104;
}

/// Raios. O DRIP usa cantos contidos: técnico, não "fofo".
abstract final class Radii {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

/// Tempos e curvas do movimento.
abstract final class Motion {
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 480);
  static const reveal = Duration(milliseconds: 820);

  /// Saída longa e suave: assinatura das entradas do DRIP.
  static const Curve out = Cubic(0.16, 1, 0.3, 1);
  static const Curve inOut = Cubic(0.65, 0, 0.35, 1);
  static const Curve exit = Cubic(0.7, 0, 0.84, 0);

  /// Intervalo entre itens em entradas escalonadas.
  static const stagger = Duration(milliseconds: 60);
}

/// Tons de estúdio usados como fundo das artes de produto.
/// Cada lançamento escolhe um índice; a arte muda sem mexer nas telas.
abstract final class StudioTones {
  static const List<List<Color>> backdrops = [
    [Color(0xFF3A3B3E), Color(0xFF151516)], // grafite
    [Color(0xFFC9CCD8), Color(0xFF7D8190)], // prata
    [Color(0xFF8ED8F0), Color(0xFF2E6C86)], // gelo
    [Color(0xFFE4E2DA), Color(0xFFA9A69B)], // osso
    [Color(0xFF202124), Color(0xFF050505)], // tinta
    [Color(0xFF5B6270), Color(0xFF22252B)], // aço
  ];

  static const List<List<Color>> metals = [
    [Color(0xFFF2F3F7), Color(0xFF8A8D98), Color(0xFF2A2B30)],
    [Color(0xFF2C2D31), Color(0xFF111113), Color(0xFF000000)],
    [Color(0xFFFFFFFF), Color(0xFFD8DAE2), Color(0xFF6E7280)],
    [Color(0xFF3B3C40), Color(0xFF17171A), Color(0xFF050505)],
    [Color(0xFFDADDE8), Color(0xFF777B88), Color(0xFF26272C)],
    [Color(0xFFF4F4F1), Color(0xFFAEB2C0), Color(0xFF3C3F48)],
  ];

  /// Indica se o fundo é claro (para escolher a cor do texto por cima).
  static bool isLight(int tone) => tone == 1 || tone == 2 || tone == 3;
}
