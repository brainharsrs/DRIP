import 'dart:convert';

/// Usuário autenticado.
class AppUser {
  const AppUser({required this.uid, required this.name, required this.email});

  final String uid;
  final String name;
  final String email;

  String get firstName => name.trim().split(' ').first;
}

/// Tipos de alerta que o usuário pode ligar ou desligar.
enum NotifPref {
  savedDrops('Drops salvos', 'Avisos antes de um item da Want List abrir.'),
  followedBrands('Marcas que acompanho', 'Novos lançamentos dessas marcas.'),
  liveNow('Ao vivo agora', 'Quando um drop salvo acaba de abrir.'),
  editorial('Novidades do DRIP', 'Atualizações importantes do aplicativo.');

  const NotifPref(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

/// Dados privados do usuário: o que ele salvou, segue e prefere.
class UserData {
  const UserData({
    this.wantList = const {},
    this.following = const {},
    this.interests = const {},
    this.readActivity = const {},
    this.notifOff = const {},
  });

  /// IDs de drops salvos.
  final Set<String> wantList;

  /// IDs de marcas acompanhadas.
  final Set<String> following;

  /// Nomes de [DropCategory] de interesse.
  final Set<String> interests;

  /// IDs de atividades já lidas.
  final Set<String> readActivity;

  /// Preferências de notificação desligadas (por nome). Padrão: tudo ligado.
  final Set<String> notifOff;

  bool wants(String dropId) => wantList.contains(dropId);
  bool follows(String brandId) => following.contains(brandId);
  bool notifEnabled(NotifPref p) => !notifOff.contains(p.name);

  UserData copyWith({
    Set<String>? wantList,
    Set<String>? following,
    Set<String>? interests,
    Set<String>? readActivity,
    Set<String>? notifOff,
  }) => UserData(
    wantList: wantList ?? this.wantList,
    following: following ?? this.following,
    interests: interests ?? this.interests,
    readActivity: readActivity ?? this.readActivity,
    notifOff: notifOff ?? this.notifOff,
  );

  Map<String, dynamic> toMap() => {
    'wantList': wantList.toList(),
    'following': following.toList(),
    'interests': interests.toList(),
    'readActivity': readActivity.toList(),
    'notifOff': notifOff.toList(),
  };

  factory UserData.fromMap(Map<String, dynamic>? m) {
    Set<String> set(String k) => {...?(m?[k] as List?)?.whereType<String>()};
    return UserData(
      wantList: set('wantList'),
      following: set('following'),
      interests: set('interests'),
      readActivity: set('readActivity'),
      notifOff: set('notifOff'),
    );
  }

  String encode() => jsonEncode(toMap());
  factory UserData.decode(String? raw) => raw == null
      ? const UserData()
      : UserData.fromMap(jsonDecode(raw) as Map<String, dynamic>);
}

enum ActivityKind { live, soon, brandDrop, system }

/// Um item da central de atividades.
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.dropId,
    this.brandId,
    this.read = false,
  });

  final String id;
  final ActivityKind kind;
  final String title;
  final String body;
  final DateTime at;
  final String? dropId;
  final String? brandId;
  final bool read;

  ActivityItem asRead(bool value) => ActivityItem(
    id: id,
    kind: kind,
    title: title,
    body: body,
    at: at,
    dropId: dropId,
    brandId: brandId,
    read: value,
  );
}
