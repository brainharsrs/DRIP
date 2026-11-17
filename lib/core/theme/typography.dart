import 'package:material_ui/material_ui.dart';

/// Tipografia do DRIP: uma única família variável (Archivo) em três vozes.
///
/// - **Display**: condensada e pesada, para palavras gigantes.
/// - **Texto**: largura normal, para títulos e leitura.
/// - **Label**: expandida, caixa alta, só para *valores* curtos
///   (status, datas, marcas). Nunca como rótulo acima de um título.
///
/// Regras: quanto maior o texto, mais apertados o espaçamento entre letras
/// e a entrelinha; nada abaixo de 11pt.
abstract final class DripType {
  static const family = 'Archivo';

  static TextStyle _v(
    double size, {
    required double wght,
    double wdth = 100,
    double height = 1.3,
    double trackingEm = 0,
    bool tabular = false,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height,
      letterSpacing: size * trackingEm,
      fontWeight: FontWeight.values[((wght / 100).round() - 1).clamp(0, 8)],
      fontVariations: [
        FontVariation('wght', wght),
        FontVariation('wdth', wdth),
      ],
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// Variações da palavra gigante (ver `GiantWord`).
  static const giantWeight = 900.0;
  static const giantWidth = 62.0;

  /// Título de destaque em telas de entrada (onboarding, auth).
  static final displayM = _v(
    44,
    wght: 800,
    wdth: 72,
    height: 0.96,
    trackingEm: -0.01,
  );

  /// Título grande das abas (colapsa ao rolar).
  static final largeTitle = _v(32, wght: 700, height: 1.08, trackingEm: -0.03);

  /// Título de produto e de seção.
  static final title = _v(24, wght: 650, height: 1.14, trackingEm: -0.025);
  static final headline = _v(19, wght: 620, height: 1.2, trackingEm: -0.015);
  static final subhead = _v(16, wght: 580, height: 1.25, trackingEm: -0.01);

  static final bodyL = _v(17, wght: 400, height: 1.5, trackingEm: -0.005);
  static final body = _v(15, wght: 400, height: 1.5);
  static final caption = _v(13, wght: 450, height: 1.4, trackingEm: 0.005);
  static final footnote = _v(12, wght: 450, height: 1.35, trackingEm: 0.01);

  /// Valor curto em caixa alta: status, marca, data.
  static final label = _v(
    11,
    wght: 700,
    wdth: 120,
    height: 1.2,
    trackingEm: 0.08,
  );
  static final labelL = _v(
    13,
    wght: 700,
    wdth: 116,
    height: 1.2,
    trackingEm: 0.06,
  );

  /// Datas, horas e preços: algarismos tabulares.
  static final data = _v(15, wght: 560, wdth: 94, height: 1.2, tabular: true);
  static final dataM = _v(
    19,
    wght: 650,
    wdth: 92,
    height: 1.1,
    trackingEm: -0.01,
    tabular: true,
  );
  static final dataL = _v(
    30,
    wght: 720,
    wdth: 80,
    height: 1,
    trackingEm: -0.015,
    tabular: true,
  );

  static final button = _v(15, wght: 650, height: 1.1, trackingEm: -0.005);
  static final tab = _v(10.5, wght: 600, height: 1.1, trackingEm: 0.01);
}
