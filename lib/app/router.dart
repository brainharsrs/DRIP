import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/motion/motion.dart';
import '../data/providers.dart';
import '../features/activity/activity_screen.dart';
import '../features/authentication/forgot_password_screen.dart';
import '../features/authentication/login_screen.dart';
import '../features/authentication/signup_screen.dart';
import '../features/brands/brand_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/drops/drop_details_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';
import '../features/want_list/want_list_screen.dart';
import 'routes.dart';

export 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Decide para onde a pessoa vai conforme o momento:
/// abertura → onboarding (1ª vez) → login → app.
String? resolveRedirect({
  required String location,
  required bool splashDone,
  required bool authLoading,
  required bool loggedIn,
  required bool onboarded,
}) {
  if (!splashDone || authLoading) {
    return location == Routes.splash ? null : Routes.splash;
  }
  final atAuth =
      location == Routes.login ||
      location == Routes.signup ||
      location == Routes.forgot;
  if (!loggedIn) {
    if (atAuth) return null;
    if (!onboarded) {
      return location == Routes.onboarding ? null : Routes.onboarding;
    }
    return Routes.login;
  }
  final atGate =
      atAuth || location == Routes.splash || location == Routes.onboarding;
  return atGate ? Routes.discover : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Reavalia o redirecionamento sempre que sessão/abertura/onboarding mudam.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  void bump() => refresh.value++;
  ref.listen(authStateProvider, (_, _) => bump());
  ref.listen(onboardingSeenProvider, (_, _) => bump());
  ref.listen(splashDoneProvider, (_, _) => bump());

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      return resolveRedirect(
        location: state.matchedLocation,
        splashDone: ref.read(splashDoneProvider),
        authLoading: auth.isLoading && !auth.hasValue,
        loggedIn: auth.value != null,
        onboarded: ref.read(onboardingSeenProvider),
      );
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) => dripPage(
          key: state.pageKey,
          fadeOnly: true,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) => dripPage(
          key: state.pageKey,
          fadeOnly: true,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) => dripPage(
          key: state.pageKey,
          fadeOnly: true,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: Routes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: Routes.forgot,
        builder: (context, state) =>
            ForgotPasswordScreen(initialEmail: state.extra as String?),
      ),
      StatefulShellRoute(
        pageBuilder: (context, state, shell) => dripPage(
          key: state.pageKey,
          fadeOnly: true,
          child: AppShell(navigationShell: shell),
        ),
        navigatorContainerBuilder: (context, shell, children) =>
            BranchSwitcher(index: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.discover,
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.explore,
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.wantList,
                builder: (context, state) => const WantListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.activity,
                builder: (context, state) => const ActivityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Telas de detalhe: abrem por cima das abas, com a transição padrão
      // da plataforma (voltar preditivo no Android, arrastar da borda no iOS).
      GoRoute(
        path: '/drop/:id',
        builder: (context, state) => DropDetailsScreen(
          dropId: state.pathParameters['id']!,
          heroTag: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/brand/:id',
        builder: (context, state) =>
            BrandScreen(brandId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/legal/:doc',
        builder: (context, state) =>
            LegalScreen(doc: state.pathParameters['doc']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
