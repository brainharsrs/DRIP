import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/components/liquid_glass.dart';
import 'data/providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // O conteúdo vai de borda a borda; as telas respeitam as áreas seguras.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Vidro líquido: o shader carrega em paralelo; até lá, vale o fallback.
  LiquidGlass.preload();

  final prefs = await SharedPreferences.getInstance();
  final firebaseReady = await _initFirebase();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const DripApp(),
    ),
  );
}

/// Liga o Firebase se o projeto já foi configurado (`flutterfire configure`).
///
/// Sem configuração, o arquivo provisório `firebase_options.dart` lança
/// [UnsupportedError] e o app segue em modo demonstração, com dados locais.
/// Qualquer outro erro é um problema real de configuração e não é escondido.
Future<bool> _initFirebase() async {
  // `--dart-define=DRIP_DEMO=true` força o modo demonstração mesmo com o
  // Firebase configurado (útil para testar telas sem tocar no projeto real).
  if (const bool.fromEnvironment('DRIP_DEMO')) return false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (const bool.fromEnvironment('DRIP_EMULATOR')) {
      // Firebase local (tool/dev.ps1): dados e contas de teste, sem tocar
      // no projeto real.
      final host = _emulatorHost();
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      debugPrint('[DRIP] Usando os emuladores do Firebase em $host.');
    } else {
      // Cache offline: Want List e catálogo continuam visíveis sem internet.
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    }
    return true;
  } on UnsupportedError catch (e) {
    debugPrint('[DRIP] Firebase não configurado: modo demonstração. $e');
    return false;
  }
}

/// Onde estão os emuladores: o IP passado em `DRIP_EMULATOR_HOST` (celular
/// na mesma rede Wi-Fi); `10.0.2.2` no emulador do Android, que é como ele
/// enxerga o computador; `localhost` no resto.
String _emulatorHost() {
  const custom = String.fromEnvironment('DRIP_EMULATOR_HOST');
  if (custom.isNotEmpty) return custom;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return 'localhost';
}
