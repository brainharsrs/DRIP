/// Estado de um lançamento em relação ao momento atual.
enum DropStatus {
  upcoming('Em breve'),
  live('Ao vivo'),
  released('Lançado'),
  tbd('Data a definir');

  const DropStatus(this.label);
  final String label;
}

enum DropCategory {
  sneakers('Sneakers'),
  apparel('Vestuário'),
  accessories('Acessórios');

  const DropCategory(this.label);
  final String label;

  static DropCategory parse(String? raw) => DropCategory.values.firstWhere(
    (c) => c.name == raw,
    orElse: () => DropCategory.sneakers,
  );
}

/// Silhueta usada pela arte de demonstração quando não há foto.
enum DropArt {
  sneaker,
  hoodie,
  tee,
  cap,
  bag;

  static DropArt parse(String? raw) =>
      DropArt.values.firstWhere((a) => a.name == raw, orElse: () => sneaker);
}

/// Um lançamento (drop) cadastrado pela equipe do DRIP.
class Drop {
  const Drop({
    required this.id,
    required this.name,
    required this.brandId,
    required this.brandName,
    required this.category,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrls = const [],
    this.price,
    this.currency = 'BRL',
    this.releaseAt,
    this.hasTime = false,
    this.officialUrl,
    this.featured = false,
    this.art = DropArt.sneaker,
    this.tone = 0,
    this.colorway,
  });

  final String id;
  final String name;
  final String brandId;
  final String brandName;
  final DropCategory category;
  final String description;
  final List<String> imageUrls;

  /// Preço em [currency]. `null` = não informado.
  final double? price;
  final String currency;

  /// Data do lançamento. `null` = a definir.
  final DateTime? releaseAt;

  /// Indica se [releaseAt] tem horário confirmado (e não só o dia).
  final bool hasTime;
  final String? officialUrl;
  final bool featured;
  final DropArt art;
  final int tone;
  final String? colorway;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Por quanto tempo após a abertura um drop conta como "ao vivo".
  static const liveWindow = Duration(hours: 24);

  DropStatus statusAt(DateTime now) {
    final at = releaseAt;
    if (at == null) return DropStatus.tbd;
    if (now.isBefore(at)) return DropStatus.upcoming;
    if (now.isBefore(at.add(liveWindow))) return DropStatus.live;
    return DropStatus.released;
  }

  DropStatus get status => statusAt(DateTime.now());

  /// Variação estável da arte de demonstração (0 a 2), derivada do id.
  int get variant => id.codeUnits.fold<int>(0, (a, b) => a + b) % 3;

  /// Primeira palavra do nome, para a tipografia gigante ("Arco 01" → "ARCO").
  String get poster {
    final first = name.trim().split(RegExp(r"[\s'×]+")).first;
    return first.isEmpty ? brandName : first;
  }

  /// Texto usado pela busca.
  String get searchText =>
      '$name $brandName ${category.label} ${colorway ?? ''}'.toLowerCase();

  factory Drop.fromMap(String id, Map<String, dynamic> m) {
    DateTime? date(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.tryParse(v);
      // Timestamp do Firestore (evita importar o SDK no model).
      try {
        return (v as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return Drop(
      id: id,
      name: (m['name'] ?? '') as String,
      brandId: (m['brandId'] ?? '') as String,
      brandName: (m['brandName'] ?? '') as String,
      category: DropCategory.parse(m['category'] as String?),
      description: (m['description'] ?? '') as String,
      imageUrls: [...?(m['imageUrls'] as List?)?.whereType<String>()],
      price: (m['price'] as num?)?.toDouble(),
      currency: (m['currency'] ?? 'BRL') as String,
      releaseAt: date(m['releaseAt']),
      hasTime: (m['hasTime'] ?? false) as bool,
      officialUrl: m['officialUrl'] as String?,
      featured: (m['featured'] ?? false) as bool,
      art: DropArt.parse(m['art'] as String?),
      tone: ((m['tone'] ?? 0) as num).toInt(),
      colorway: m['colorway'] as String?,
      createdAt: date(m['createdAt']) ?? DateTime.now(),
      updatedAt: date(m['updatedAt']) ?? DateTime.now(),
    );
  }
}
