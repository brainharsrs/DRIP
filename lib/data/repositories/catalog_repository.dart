import 'package:cloud_firestore/cloud_firestore.dart';

import '../demo/demo_catalog.dart';
import '../models/brand.dart';
import '../models/drop.dart';

/// Catálogo público do DRIP: marcas e lançamentos cadastrados pela equipe.
abstract interface class CatalogRepository {
  Stream<List<Drop>> watchDrops();
  Stream<List<Brand>> watchBrands();

  /// `true` quando o conteúdo é de demonstração (não são lançamentos reais).
  bool get isDemo;
}

/// Catálogo de demonstração, usado enquanto o Firebase não está configurado.
class DemoCatalogRepository implements CatalogRepository {
  DemoCatalogRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  bool get isDemo => true;

  @override
  Stream<List<Drop>> watchDrops() => Stream.value(DemoCatalog.drops(_clock()));

  @override
  Stream<List<Brand>> watchBrands() => Stream.value(DemoCatalog.brands);
}

/// Catálogo real, lido do Cloud Firestore em tempo real.
///
/// Coleções: `brands/{id}` e `drops/{id}` (só os com `published == true`).
/// O MVP carrega o catálogo inteiro, que é curado e pequeno; quando crescer,
/// o próximo passo é paginar por `releaseAt`.
class FirestoreCatalogRepository implements CatalogRepository {
  FirestoreCatalogRepository(this._db);

  final FirebaseFirestore _db;

  /// Teto de segurança de leituras por abertura do app.
  static const _limit = 400;

  @override
  bool get isDemo => false;

  @override
  Stream<List<Drop>> watchDrops() => _db
      .collection('drops')
      .where('published', isEqualTo: true)
      .limit(_limit)
      .snapshots()
      .map((s) => [for (final d in s.docs) Drop.fromMap(d.id, d.data())]);

  @override
  Stream<List<Brand>> watchBrands() => _db
      .collection('brands')
      .limit(_limit)
      .snapshots()
      .map((s) => [for (final d in s.docs) Brand.fromMap(d.id, d.data())]);
}
