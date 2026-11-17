import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/links.dart';
import 'models/brand.dart';
import 'models/drop.dart';
import 'models/user.dart';
import 'repositories/auth_repository.dart';
import 'repositories/catalog_repository.dart';
import 'repositories/firebase_auth_repository.dart';
import 'repositories/local_auth_repository.dart';
import 'repositories/user_data_repository.dart';
import 'services/push_service.dart';

// ---------------------------------------------------------------------------
// Infraestrutura
// ---------------------------------------------------------------------------

/// Preferências locais. Sobrescrito no `main()` com a instância carregada.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider não foi inicializado'),
);

/// `true` quando o Firebase foi inicializado (definido no `main()`).
/// Com `false`, o app roda em modo demonstração: dados só neste aparelho.
final firebaseReadyProvider = Provider<bool>((ref) => false);

/// Relógio injetável (os testes fixam a hora).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Pulsa a cada 30 s para que status ("ao vivo") e prazos se atualizem sozinhos.
final tickProvider = StreamProvider<int>(
  (ref) => Stream.periodic(const Duration(seconds: 30), (i) => i),
);

/// "Agora", renovado a cada pulso.
final nowProvider = Provider<DateTime>((ref) {
  ref.watch(tickProvider);
  return ref.watch(clockProvider)();
});

final linkOpenerProvider = Provider<LinkOpener>((ref) => openExternalLink);

// ---------------------------------------------------------------------------
// Repositórios (Firebase em produção, locais no modo demonstração)
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(firebaseReadyProvider)) {
    return FirebaseAuthRepository(
      fb.FirebaseAuth.instance,
      FirebaseFirestore.instance,
    );
  }
  return LocalAuthRepository(ref.watch(sharedPrefsProvider));
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  if (ref.watch(firebaseReadyProvider)) {
    return FirestoreCatalogRepository(FirebaseFirestore.instance);
  }
  return DemoCatalogRepository(clock: ref.watch(clockProvider));
});

final userDataRepositoryProvider = Provider<UserDataRepository>((ref) {
  if (ref.watch(firebaseReadyProvider)) {
    return FirestoreUserDataRepository(FirebaseFirestore.instance);
  }
  return LocalUserDataRepository(ref.watch(sharedPrefsProvider));
});

final pushServiceProvider = Provider<PushService>((ref) {
  // Push só existe na web, no Android e no iOS/macOS. No Windows o plugin
  // de mensagens não tem implementação e qualquer chamada falharia.
  final pushPlatform =
      kIsWeb ||
      const {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }.contains(defaultTargetPlatform);
  if (ref.watch(firebaseReadyProvider) && pushPlatform) {
    return FirebasePushService(
      FirebaseMessaging.instance,
      FirebaseFirestore.instance,
    );
  }
  return const NoPushService();
});

// ---------------------------------------------------------------------------
// Sessão e dados do usuário
// ---------------------------------------------------------------------------

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authState(),
);

final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authStateProvider).value,
);

final userDataStreamProvider = StreamProvider<UserData>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream.value(const UserData());
  return ref.watch(userDataRepositoryProvider).watch(uid);
});

/// Dados do usuário já "desembrulhados" (vazio enquanto carrega).
final userDataProvider = Provider<UserData>(
  (ref) => ref.watch(userDataStreamProvider).value ?? const UserData(),
);

/// Ações do usuário sobre seus próprios dados.
class UserActions {
  UserActions(this._ref);
  final Ref _ref;

  String? get _uid => _ref.read(currentUserProvider)?.uid;
  UserDataRepository get _repo => _ref.read(userDataRepositoryProvider);

  /// Salva ou remove o drop da Want List. Devolve o novo estado.
  Future<bool> toggleWant(String dropId) async {
    final uid = _uid;
    if (uid == null) return false;
    final next = !_ref.read(userDataProvider).wants(dropId);
    await _repo.setWant(uid, dropId, next);
    return next;
  }

  Future<void> setWant(String dropId, bool value) async {
    final uid = _uid;
    if (uid != null) await _repo.setWant(uid, dropId, value);
  }

  /// Passa a acompanhar ou deixa de acompanhar a marca. Devolve o novo estado.
  Future<bool> toggleFollow(String brandId) async {
    final uid = _uid;
    if (uid == null) return false;
    final next = !_ref.read(userDataProvider).follows(brandId);
    await _repo.setFollow(uid, brandId, next);
    return next;
  }

  Future<void> setInterest(String category, bool value) async {
    final uid = _uid;
    if (uid != null) await _repo.setInterest(uid, category, value);
  }

  Future<void> setNotifPref(NotifPref pref, bool enabled) async {
    final uid = _uid;
    if (uid != null) await _repo.setNotifPref(uid, pref, enabled);
  }

  Future<void> markRead(Iterable<String> ids) async {
    final uid = _uid;
    if (uid != null) await _repo.markRead(uid, ids);
  }
}

final userActionsProvider = Provider<UserActions>(UserActions.new);

// ---------------------------------------------------------------------------
// Catálogo
// ---------------------------------------------------------------------------

final dropsProvider = StreamProvider<List<Drop>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchDrops(),
);

final brandsProvider = StreamProvider<List<Brand>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchBrands(),
);

final dropByIdProvider = Provider.family<Drop?, String>((ref, id) {
  final drops = ref.watch(dropsProvider).value ?? const <Drop>[];
  for (final d in drops) {
    if (d.id == id) return d;
  }
  return null;
});

final brandByIdProvider = Provider.family<Brand?, String>((ref, id) {
  final brands = ref.watch(brandsProvider).value ?? const <Brand>[];
  for (final b in brands) {
    if (b.id == id) return b;
  }
  return null;
});

/// Ordem cronológica do radar: ao vivo, depois os próximos (mais perto
/// primeiro), depois sem data, por fim os já lançados (mais recentes antes).
int compareByRadar(Drop a, Drop b, DateTime now) {
  int rank(Drop d) => switch (d.statusAt(now)) {
    DropStatus.live => 0,
    DropStatus.upcoming => 1,
    DropStatus.tbd => 2,
    DropStatus.released => 3,
  };
  final ra = rank(a), rb = rank(b);
  if (ra != rb) return ra.compareTo(rb);
  final da = a.releaseAt, db = b.releaseAt;
  if (da == null || db == null) return a.name.compareTo(b.name);
  return ra == 3 ? db.compareTo(da) : da.compareTo(db);
}

final dropsOfBrandProvider = Provider.family<List<Drop>, String>((ref, id) {
  final now = ref.watch(nowProvider);
  final drops = ref.watch(dropsProvider).value ?? const <Drop>[];
  return drops.where((d) => d.brandId == id).toList()
    ..sort((a, b) => compareByRadar(a, b, now));
});

// ---------------------------------------------------------------------------
// Preferências do aparelho
// ---------------------------------------------------------------------------

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'drip.theme';

  @override
  ThemeMode build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_key);
    // O escuro é a direção visual da marca; claro e "sistema" são opções.
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.dark,
    );
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPrefsProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class OnboardingNotifier extends Notifier<bool> {
  static const _key = 'drip.onboarded';

  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(_key) ?? false;

  void complete() {
    state = true;
    ref.read(sharedPrefsProvider).setBool(_key, true);
  }
}

/// `true` depois que a pessoa passou pelo onboarding neste aparelho.
final onboardingSeenProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);

class SplashNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void finish() => state = true;
}

/// `true` quando a animação de abertura terminou.
final splashDoneProvider = NotifierProvider<SplashNotifier, bool>(
  SplashNotifier.new,
);
