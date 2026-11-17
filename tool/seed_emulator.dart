// Preenche os emuladores do Firebase com o catálogo de demonstração e com
// contas de teste prontas para entrar.
//
// Uso (com os emuladores ligados; o tool/dev.ps1 já faz tudo):
//   dart run tool/seed_emulator.dart
//
// Só fala com os emuladores locais (127.0.0.1). O projeto real não é tocado.
//
// Pode rodar quantas vezes quiser:
//  - marcas e drops são regravados (as datas acompanham o dia de hoje);
//  - contas e documentos de pessoas só são criados se ainda não existirem,
//    então o que você salvou ou mudou no app continua lá.

import 'dart:convert';
import 'dart:io';

import 'package:drip/data/demo/demo_catalog.dart';
import 'package:drip/data/models/brand.dart';
import 'package:drip/data/models/drop.dart';

const _project = 'demo-drip';
const _host = '127.0.0.1';
const _authPort = 9099;
const _firestorePort = 8080;

/// Contas de teste. Só existem nos emuladores.
const testPassword = 'Drip@2026';

class _TestAccount {
  const _TestAccount({
    required this.email,
    required this.name,
    this.admin = false,
    this.wantList = const [],
    this.following = const [],
    this.interests = const [],
    this.withNotifications = false,
  });

  final String email;
  final String name;
  final bool admin;
  final List<String> wantList;
  final List<String> following;
  final List<String> interests;
  final bool withNotifications;
}

const _accounts = [
  // Pessoa que já usa o app: Want List, marcas e avisos preenchidos.
  _TestAccount(
    email: 'ana@drip.test',
    name: 'Ana Ribeiro',
    wantList: [
      'vertice-arco-01',
      'cromo-liga-prata-fria',
      'kalt-casulo',
      'asfalto-noturno-2',
      'orla-mare-crossbody',
    ],
    following: ['vertice', 'cromo', 'asfalto'],
    interests: ['sneakers', 'apparel'],
    withNotifications: true,
  ),
  // Conta recém-criada: tudo vazio, para ver os estados vazios.
  _TestAccount(email: 'novo@drip.test', name: 'Conta Nova'),
  // Equipe: pode cadastrar marcas e drops pelas regras (admin: true).
  _TestAccount(
    email: 'equipe@drip.test',
    name: 'Equipe DRIP',
    admin: true,
    following: ['monofase', 'orla'],
    interests: ['sneakers', 'apparel', 'accessories'],
  ),
];

final _http = HttpClient();

Future<void> main() async {
  stdout.writeln('Aguardando os emuladores do Firebase...');
  await _waitFor(_authPort, 'Authentication');
  await _waitFor(_firestorePort, 'Firestore');

  final now = DateTime.now();
  final brands = DemoCatalog.brands;
  final drops = DemoCatalog.drops(now);

  for (final b in brands) {
    await _firestore('PATCH', 'brands/${b.id}', _brandMap(b));
  }
  for (final d in drops) {
    await _firestore('PATCH', 'drops/${d.id}', _dropMap(d));
  }
  stdout.writeln('Catálogo: ${brands.length} marcas e ${drops.length} drops.');

  for (final a in _accounts) {
    final uid = await _ensureAccount(a);
    final created = await _createIfMissing('users', uid, {
      'name': a.name,
      'email': a.email,
      'createdAt': now,
      'updatedAt': now,
      'wantList': a.wantList,
      'following': a.following,
      'interests': a.interests,
      'readActivity': <String>[],
      'notifOff': <String>[],
    });
    if (a.withNotifications) {
      await _seedNotifications(uid, drops, now);
    }
    stdout.writeln(
      '  ${a.email.padRight(18)} ${a.admin ? 'equipe' : 'pessoa'}'
      '${created ? '' : ' (já existia, dados mantidos)'}',
    );
  }

  stdout
    ..writeln('Contas prontas. Senha de todas: $testPassword')
    ..writeln('Painel dos emuladores: http://localhost:4000');
  _http.close();
}

// ---------------------------------------------------------------------------
// Conteúdo

Map<String, Object?> _brandMap(Brand b) => {
  'name': b.name,
  'tagline': b.tagline,
  'description': b.description,
  'websiteUrl': b.websiteUrl,
  'logoUrl': b.logoUrl,
  'coverUrl': b.coverUrl,
  'origin': b.origin,
  'tone': b.tone,
};

Map<String, Object?> _dropMap(Drop d) => {
  'published': true,
  'name': d.name,
  'brandId': d.brandId,
  'brandName': d.brandName,
  'category': d.category.name,
  'description': d.description,
  'imageUrls': d.imageUrls,
  'price': d.price,
  'currency': d.currency,
  'releaseAt': d.releaseAt,
  'hasTime': d.hasTime,
  'officialUrl': d.officialUrl,
  'featured': d.featured,
  'art': d.art.name,
  'tone': d.tone,
  'colorway': d.colorway,
  'createdAt': d.createdAt,
  'updatedAt': d.updatedAt,
};

/// Avisos que o servidor teria gravado para quem salvou esses drops.
Future<void> _seedNotifications(
  String uid,
  List<Drop> drops,
  DateTime now,
) async {
  Drop? byId(String id) => drops.where((d) => d.id == id).firstOrNull;
  final items = <String, Map<String, Object?>>{};

  final arco = byId('vertice-arco-01');
  if (arco != null) {
    items['seed-1'] = {
      'title': '${arco.name} abre em breve',
      'body': 'Um item da sua Want List está quase saindo. Fique de olho.',
      'at': now.subtract(const Duration(minutes: 25)),
      'dropId': arco.id,
      'brandId': arco.brandId,
    };
  }
  final asfalto = byId('asfalto-noturno-2');
  if (asfalto != null) {
    items['seed-2'] = {
      'title': 'Novo drop da ${asfalto.brandName}',
      'body': '${asfalto.name} entrou no radar.',
      'at': now.subtract(const Duration(hours: 5)),
      'dropId': asfalto.id,
      'brandId': asfalto.brandId,
    };
  }
  items['seed-3'] = {
    'title': 'Boas-vindas ao DRIP',
    'body': 'Salve drops na Want List para receber avisos antes de abrirem.',
    'at': now.subtract(const Duration(days: 2)),
  };

  for (final e in items.entries) {
    await _createIfMissing('users/$uid/notifications', e.key, e.value);
  }
}

// ---------------------------------------------------------------------------
// Authentication (emulador)

/// Devolve o UID da conta, criando-a se ainda não existir.
Future<String> _ensureAccount(_TestAccount a) async {
  final found = await _auth(
    'projects/$_project/accounts:lookup',
    {
      'email': [a.email],
    },
  );
  final users = found['users'] as List?;
  String uid;
  if (users != null && users.isNotEmpty) {
    uid = (users.first as Map)['localId'] as String;
  } else {
    final made = await _auth('accounts:signUp?key=demo', {
      'email': a.email,
      'password': testPassword,
      'displayName': a.name,
      'returnSecureToken': true,
    }, owner: false);
    uid = made['localId'] as String;
  }
  await _auth('projects/$_project/accounts:update', {
    'localId': uid,
    'emailVerified': true,
    'customAttributes': jsonEncode(a.admin ? {'admin': true} : {}),
  });
  return uid;
}

Future<Map<String, dynamic>> _auth(
  String path,
  Map<String, Object?> body, {
  bool owner = true,
}) async {
  final res = await _send(
    'POST',
    Uri.parse(
      'http://$_host:$_authPort/identitytoolkit.googleapis.com/v1/$path',
    ),
    body,
    owner: owner,
  );
  if (res.status >= 300) {
    throw StateError('Authentication respondeu ${res.status}: ${res.body}');
  }
  return res.json;
}

// ---------------------------------------------------------------------------
// Firestore (emulador, REST). "Bearer owner" ignora as regras de segurança,
// como o Admin SDK faria; só funciona no emulador.

String get _docs =>
    'http://$_host:$_firestorePort/v1/projects/$_project/databases/(default)/documents';

Future<void> _firestore(
  String method,
  String path,
  Map<String, Object?> data,
) async {
  final res = await _send(method, Uri.parse('$_docs/$path'), {
    'fields': _fields(data),
  });
  if (res.status >= 300) {
    throw StateError('Firestore respondeu ${res.status} em $path: ${res.body}');
  }
}

/// Cria o documento só se ele não existir. Devolve `true` se criou.
Future<bool> _createIfMissing(
  String collection,
  String id,
  Map<String, Object?> data,
) async {
  final res = await _send(
    'POST',
    Uri.parse('$_docs/$collection?documentId=${Uri.encodeQueryComponent(id)}'),
    {'fields': _fields(data)},
  );
  if (res.status == 409) return false;
  if (res.status >= 300) {
    throw StateError(
      'Firestore respondeu ${res.status} em $collection/$id: ${res.body}',
    );
  }
  return true;
}

Map<String, Object?> _fields(Map<String, Object?> data) => {
  for (final e in data.entries)
    if (e.value != null) e.key: _value(e.value),
};

Map<String, Object?> _value(Object? v) => switch (v) {
  null => {'nullValue': null},
  String s => {'stringValue': s},
  bool b => {'booleanValue': b},
  int i => {'integerValue': '$i'},
  double d => {'doubleValue': d},
  DateTime t => {'timestampValue': t.toUtc().toIso8601String()},
  Iterable<Object?> l => {
    'arrayValue': {
      if (l.isNotEmpty) 'values': [for (final x in l) _value(x)],
    },
  },
  Map<String, Object?> m => {
    'mapValue': {'fields': _fields(m)},
  },
  _ => throw ArgumentError('Tipo sem conversão para o Firestore: $v'),
};

// ---------------------------------------------------------------------------
// HTTP

typedef _Res = ({int status, String body, Map<String, dynamic> json});

Future<_Res> _send(
  String method,
  Uri uri,
  Map<String, Object?> body, {
  bool owner = true,
}) async {
  final req = await _http.openUrl(method, uri);
  req.headers.contentType = ContentType.json;
  if (owner) req.headers.set('Authorization', 'Bearer owner');
  req.add(utf8.encode(jsonEncode(body)));
  final res = await req.close();
  final text = await utf8.decodeStream(res);
  Map<String, dynamic> json = const {};
  try {
    final parsed = jsonDecode(text);
    if (parsed is Map<String, dynamic>) json = parsed;
  } on FormatException {
    // Corpo vazio ou texto: o status basta.
  }
  return (status: res.statusCode, body: text, json: json);
}

Future<void> _waitFor(int port, String name) async {
  final deadline = DateTime.now().add(const Duration(minutes: 3));
  while (true) {
    try {
      final s = await Socket.connect(
        _host,
        port,
        timeout: const Duration(seconds: 1),
      );
      s.destroy();
      return;
    } on SocketException {
      if (DateTime.now().isAfter(deadline)) {
        stderr.writeln(
          'O emulador de $name (porta $port) não respondeu. '
          'Ele está ligado? Rode: firebase emulators:start',
        );
        exit(1);
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }
}
