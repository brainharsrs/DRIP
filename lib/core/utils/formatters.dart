import 'dart:math' as math;

/// Formatação de datas, horas e preços em pt-BR.
///
/// Feito à mão (sem `intl`) porque o app só precisa de poucos formatos,
/// todos fixos e com a cara da marca (meses abreviados em caixa alta).
abstract final class Fmt {
  static const _months = [
    'JAN',
    'FEV',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OUT',
    'NOV',
    'DEZ',
  ];
  static const _monthsLong = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  static const _weekdays = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
  static const _weekdaysLong = [
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];

  static String two(int n) => n.toString().padLeft(2, '0');

  /// "24"
  static String day(DateTime d) => two(d.day);

  /// "NOV"
  static String month(DateTime d) => _months[d.month - 1];

  /// "24 NOV"
  static String dayMonth(DateTime d) => '${two(d.day)} ${month(d)}';

  /// "SEG"
  static String weekday(DateTime d) => _weekdays[d.weekday - 1];

  /// "10:00"
  static String time(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

  /// "24 de novembro de 2026"
  static String longDate(DateTime d) =>
      '${d.day} de ${_monthsLong[d.month - 1]} de ${d.year}';

  /// "segunda-feira, 24 de novembro"
  static String spokenDate(DateTime d) =>
      '${_weekdaysLong[d.weekday - 1]}, ${d.day} de ${_monthsLong[d.month - 1]}';

  /// "R$ 1.299,90"
  static String price(double value, [String currency = 'BRL']) {
    final symbol = switch (currency) {
      'BRL' => r'R$',
      'USD' => r'US$',
      'EUR' => '€',
      _ => currency,
    };
    final cents = (value * 100).round();
    final whole = (cents ~/ 100).toString();
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write('.');
      buf.write(whole[i]);
    }
    return '$symbol $buf,${two(cents % 100)}';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Diferença em dias de calendário (hoje → amanhã = 1).
  static int calendarDays(DateTime from, DateTime to) =>
      (_dateOnly(to).difference(_dateOnly(from)).inHours / 24).round();

  /// "em 12 min", "em 3 h", "amanhã", "em 5 dias"
  static String untilText(DateTime target, DateTime now) {
    final diff = target.difference(now);
    if (diff.isNegative) return 'agora';
    if (diff.inMinutes < 60) return 'em ${math.max(1, diff.inMinutes)} min';
    final days = calendarDays(now, target);
    if (days == 0 || diff.inHours < 12) return 'em ${diff.inHours} h';
    if (days == 1) return 'amanhã';
    return 'em $days dias';
  }

  /// "agora", "há 12 min", "há 3 h", "ontem", "há 5 dias"
  static String sinceText(DateTime at, DateTime now) {
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    final days = calendarDays(at, now);
    if (days <= 1) return 'ontem';
    return 'há $days dias';
  }

  /// Partes de uma contagem regressiva: dias, horas, minutos, segundos.
  static ({String d, String h, String m, String s}) countdown(Duration left) {
    final t = left.isNegative ? Duration.zero : left;
    return (
      d: two(t.inDays),
      h: two(t.inHours % 24),
      m: two(t.inMinutes % 60),
      s: two(t.inSeconds % 60),
    );
  }
}
