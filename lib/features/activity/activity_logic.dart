import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/drop.dart';
import '../../data/models/user.dart';
import '../../data/providers.dart';

/// Com quanta antecedência um drop salvo vira aviso.
const kSoonWindow = Duration(hours: 72);

/// Por quanto tempo um drop novo de marca acompanhada aparece como novidade.
const kNewDropWindow = Duration(days: 14);

/// Monta a central de atividades a partir do que a pessoa salvou e segue.
///
/// Os avisos são calculados no aparelho, a partir do catálogo: funcionam
/// mesmo sem push. As notificações enviadas pelo servidor entram em [server].
List<ActivityItem> buildActivity({
  required List<Drop> drops,
  required UserData user,
  required DateTime now,
  List<ActivityItem> server = const [],
}) {
  final items = <ActivityItem>[];

  for (final d in drops) {
    final at = d.releaseAt;
    final status = d.statusAt(now);

    if (user.wants(d.id) && at != null) {
      final stamp = at.millisecondsSinceEpoch;
      if (status == DropStatus.live && user.notifEnabled(NotifPref.liveNow)) {
        items.add(
          ActivityItem(
            id: 'live:${d.id}:$stamp',
            kind: ActivityKind.live,
            title: '${d.name} está ao vivo',
            body: 'Abriu ${Fmt.sinceText(at, now)} no site da ${d.brandName}.',
            at: at,
            dropId: d.id,
          ),
        );
      } else if (status == DropStatus.upcoming &&
          at.difference(now) <= kSoonWindow &&
          user.notifEnabled(NotifPref.savedDrops)) {
        final since = at.subtract(kSoonWindow);
        items.add(
          ActivityItem(
            id: 'soon:${d.id}:$stamp',
            kind: ActivityKind.soon,
            title: '${d.name} abre ${Fmt.untilText(at, now)}',
            body: d.hasTime
                ? '${Fmt.dayMonth(at)} às ${Fmt.time(at)}. Está na sua Want List.'
                : '${Fmt.dayMonth(at)}, horário a confirmar. Está na sua Want List.',
            at: since.isBefore(d.createdAt) ? d.createdAt : since,
            dropId: d.id,
          ),
        );
      }
    }

    if (user.follows(d.brandId) &&
        user.notifEnabled(NotifPref.followedBrands) &&
        status != DropStatus.released &&
        now.difference(d.createdAt) <= kNewDropWindow) {
      final when = at == null
          ? 'Data a definir.'
          : '${Fmt.dayMonth(at)}${d.hasTime ? ' às ${Fmt.time(at)}' : ''}.';
      items.add(
        ActivityItem(
          id: 'brand:${d.id}',
          kind: ActivityKind.brandDrop,
          title: 'Novo drop de ${d.brandName}',
          body: '${d.name}. $when',
          at: d.createdAt,
          dropId: d.id,
          brandId: d.brandId,
        ),
      );
    }
  }

  if (user.notifEnabled(NotifPref.editorial)) items.addAll(server);

  items.sort((a, b) => b.at.compareTo(a.at));
  return [for (final i in items) i.asRead(user.readActivity.contains(i.id))];
}

final serverNotificationsProvider = StreamProvider<List<ActivityItem>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.watch(userDataRepositoryProvider).watchServerNotifications(uid);
});

final activityProvider = Provider<List<ActivityItem>>((ref) {
  return buildActivity(
    drops: ref.watch(dropsProvider).value ?? const [],
    user: ref.watch(userDataProvider),
    now: ref.watch(nowProvider),
    server: ref.watch(serverNotificationsProvider).value ?? const [],
  );
});

final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(activityProvider).where((a) => !a.read).length,
);
