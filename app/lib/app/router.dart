import 'package:bookia_mobile/app/app_shell.dart';
import 'package:bookia_mobile/core/widgets/placeholder_page.dart';
import 'package:bookia_mobile/features/home/presentation/pages/home_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route paths. Screens 03, 04, 08, 12 and 15 hang from the bottom bar.
abstract final class AppRoutes {
  static const home = '/home';
  static const search = '/search';
  static const map = '/map';
  static const reservations = '/reservations';
  static const profile = '/profile';
}

StatefulShellBranch _tab(String path, String title, [Widget? page]) =>
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (_, _) => page ?? PlaceholderPage(title: title),
        ),
      ],
    );

/// Builds the app router. A new instance per call keeps tests isolated.
GoRouter createRouter({String initialLocation = AppRoutes.home}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      branches: [
        _tab(AppRoutes.home, 'Inicio', const HomePage()),
        _tab(AppRoutes.search, 'Buscar'),
        _tab(AppRoutes.map, 'Mapa'),
        _tab(AppRoutes.reservations, 'Mis reservas'),
        _tab(AppRoutes.profile, 'Perfil'),
      ],
    ),
  ],
);
