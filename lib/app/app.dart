import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/components/surfaces.dart';
import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../data/providers.dart';
import '../data/services/push_service.dart';
import 'router.dart';

class DripApp extends ConsumerWidget {
  const DripApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConfig.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      scrollBehavior: const _DripScrollBehavior(),
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        // O texto acompanha o tamanho escolhido no sistema, até um teto que
        // ainda cabe nos componentes de altura fixa.
        maxScaleFactor: 1.5,
        child: _ForegroundPush(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

/// Galerias e carrosséis também podem ser arrastados com mouse e trackpad
/// (por padrão o Flutter só aceita o dedo), útil na web e em tablets.
class _DripScrollBehavior extends MaterialScrollBehavior {
  const _DripScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}

/// Mostra como aviso as notificações push que chegam com o app aberto.
class _ForegroundPush extends ConsumerStatefulWidget {
  const _ForegroundPush({required this.child});
  final Widget child;

  @override
  ConsumerState<_ForegroundPush> createState() => _ForegroundPushState();
}

class _ForegroundPushState extends ConsumerState<_ForegroundPush> {
  StreamSubscription<PushMessage>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(pushServiceProvider).foreground.listen((m) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted || m.title.isEmpty) return;
      final dropId = m.dropId;
      showToast(
        ctx,
        m.body.isEmpty ? m.title : '${m.title}\n${m.body}',
        actionLabel: dropId == null ? null : 'Ver',
        onAction: dropId == null
            ? null
            : () => ref.read(routerProvider).push('/drop/$dropId'),
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
