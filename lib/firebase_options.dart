import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuração do Firebase, lida em tempo de compilação.
///
/// As chaves do projeto não ficam no código: vêm de `firebase.local.json`
/// (fora do Git), passado com
/// `flutter run --dart-define-from-file=firebase.local.json`.
/// O modelo está em `firebase.local.example.json`.
///
/// - Sem o arquivo, [currentPlatform] lança [UnsupportedError] e o app abre
///   em modo demonstração, com dados só no aparelho.
/// - Com `DRIP_EMULATOR=true`, usa um projeto de demonstração (`demo-drip`)
///   que só existe nos emuladores locais (tool/dev.ps1).
class DefaultFirebaseOptions {
  static const _emulator = bool.fromEnvironment('DRIP_EMULATOR');

  static const _projectId = String.fromEnvironment('FB_PROJECT_ID');
  static const _senderId = String.fromEnvironment('FB_SENDER_ID');
  static const _bucket = String.fromEnvironment('FB_STORAGE_BUCKET');
  static const _authDomain = String.fromEnvironment('FB_AUTH_DOMAIN');

  static FirebaseOptions get currentPlatform {
    if (_emulator) return _demo;
    if (_projectId.isEmpty) {
      throw UnsupportedError(
        'Firebase sem configuração: rode com '
        '--dart-define-from-file=firebase.local.json.',
      );
    }
    if (kIsWeb) return _web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      // Windows usa o mesmo app web do projeto (como faz o FlutterFire CLI).
      case TargetPlatform.windows:
        return _web;
      default:
        throw UnsupportedError(
          'DRIP não tem Firebase configurado para '
          '${defaultTargetPlatform.name}.',
        );
    }
  }

  /// Projeto fictício dos emuladores. O prefixo `demo-` garante que o
  /// Firebase nunca tente falar com um projeto real.
  static const _demo = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-drip',
    authDomain: 'demo-drip.firebaseapp.com',
    storageBucket: 'demo-drip.appspot.com',
  );

  static const _web = FirebaseOptions(
    apiKey: String.fromEnvironment('FB_WEB_API_KEY'),
    appId: String.fromEnvironment('FB_WEB_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _bucket,
    measurementId: String.fromEnvironment('FB_MEASUREMENT_ID'),
  );

  static const _android = FirebaseOptions(
    apiKey: String.fromEnvironment('FB_ANDROID_API_KEY'),
    appId: String.fromEnvironment('FB_ANDROID_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _bucket,
  );

  static const _ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FB_IOS_API_KEY'),
    appId: String.fromEnvironment('FB_IOS_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _bucket,
    iosClientId: String.fromEnvironment('FB_IOS_CLIENT_ID'),
    iosBundleId: String.fromEnvironment('FB_IOS_BUNDLE_ID'),
  );
}
