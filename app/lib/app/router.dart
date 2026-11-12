import 'package:bookia_mobile/app/app_shell.dart';
import 'package:bookia_mobile/core/widgets/placeholder_page.dart';
import 'package:bookia_mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:bookia_mobile/features/home/presentation/pages/home_page.dart';
import 'package:bookia_mobile/features/search/presentation/pages/search_results_page.dart';
import 'package:bookia_mobile/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route paths. The app starts on 01 Splash; screens 03, 04, 08, 12 and 15
/// hang from the bottom bar.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/home';
  static const search = '/search';
  static const map = '/map';
  static const reservations = '/reservations';
  static const profile = '/profile';
  static const auth = '/auth';
}

StatefulShellBranch _tab(
  String path,
  String title, [
  Widget Function(GoRouterState state)? page,
]) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      builder: (_, state) =>
          page?.call(state) ??
          (path == AppRoutes.profile
              ? const AuthEntryPage()
              : PlaceholderPage(title: title)),
    ),
  ],
);

Widget _results(GoRouterState state) {
  final params = state.uri.queryParameters;
  return SearchResultsPage(
    key: ValueKey(state.uri),
    query: (q: params['q'], genre: params['genre']),
  );
}

/// Builds the app router. A new instance per call keeps tests isolated.
GoRouter createRouter({String initialLocation = AppRoutes.home}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
    GoRoute(path: AppRoutes.auth, builder: (_, _) => const AuthPage()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      branches: [
        _tab(AppRoutes.home, 'Inicio', (_) => const HomePage()),
        _tab(AppRoutes.search, 'Buscar', _results),
        _tab(AppRoutes.map, 'Mapa'),
        _tab(AppRoutes.reservations, 'Mis reservas'),
        _tab(AppRoutes.profile, 'Perfil'),
      ],
    ),
  ],
);
