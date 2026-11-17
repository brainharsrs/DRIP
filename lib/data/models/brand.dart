/// Uma marca acompanhada pelo DRIP.
class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    this.websiteUrl,
    this.logoUrl,
    this.coverUrl,
    this.origin,
    this.tone = 0,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final String? websiteUrl;
  final String? logoUrl;
  final String? coverUrl;
  final String? origin;
  final int tone;

  /// Iniciais para o monograma quando não há logo.
  String get monogram {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2));
    }
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
  }

  factory Brand.fromMap(String id, Map<String, dynamic> m) => Brand(
    id: id,
    name: (m['name'] ?? '') as String,
    tagline: (m['tagline'] ?? '') as String,
    description: (m['description'] ?? '') as String,
    websiteUrl: m['websiteUrl'] as String?,
    logoUrl: m['logoUrl'] as String?,
    coverUrl: m['coverUrl'] as String?,
    origin: m['origin'] as String?,
    tone: ((m['tone'] ?? 0) as num).toInt(),
  );
}
