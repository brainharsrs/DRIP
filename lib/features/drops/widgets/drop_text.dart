import '../../../core/utils/formatters.dart';
import '../../../data/models/drop.dart';

/// Textos prontos sobre "quando" e "quanto" de um drop, sempre no mesmo tom.
extension DropText on Drop {
  /// Linha curta de quando: "24 NOV · 10:00", "Aberto há 3 h", "Data a definir".
  String whenLine(DateTime now) {
    final at = releaseAt;
    if (at == null) return 'Data a definir';
    return switch (statusAt(now)) {
      DropStatus.live => 'Aberto ${Fmt.sinceText(at, now)}',
      DropStatus.released => 'Lançado em ${Fmt.dayMonth(at)}',
      _ => hasTime ? '${Fmt.dayMonth(at)} · ${Fmt.time(at)}' : Fmt.dayMonth(at),
    };
  }

  /// Só o horário, para listas já agrupadas por dia.
  String get timeLine {
    final at = releaseAt;
    if (at == null) return 'Data a definir';
    return hasTime ? Fmt.time(at) : 'Horário a confirmar';
  }

  String get dateValue =>
      releaseAt == null ? 'A definir' : Fmt.dayMonth(releaseAt!);

  String get timeValue {
    if (releaseAt == null) return '—';
    return hasTime ? Fmt.time(releaseAt!) : 'A confirmar';
  }

  String get priceValue =>
      price == null ? 'Não informado' : Fmt.price(price!, currency);

  /// Descrição completa para leitores de tela.
  String spoken(DateTime now) {
    final at = releaseAt;
    final when = at == null
        ? 'data a definir'
        : switch (statusAt(now)) {
            DropStatus.live => 'ao vivo, aberto ${Fmt.sinceText(at, now)}',
            DropStatus.released => 'lançado em ${Fmt.spokenDate(at)}',
            _ =>
              'abre ${Fmt.spokenDate(at)}${hasTime ? ' às ${Fmt.time(at)}' : ''}',
          };
    return '$name, $brandName, ${category.label}, $when';
  }
}
