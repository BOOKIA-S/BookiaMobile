import 'package:bookia_mobile/app/app_shell.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/core/widgets/placeholder_page.dart';
import 'package:bookia_mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:bookia_mobile/features/books/presentation/pages/book_detail_page.dart';
import 'package:bookia_mobile/features/home/presentation/pages/home_page.dart';
import 'package:bookia_mobile/features/onboarding/presentation/pages/location_permission_page.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/pages/reservation_ready_page.dart';
import 'package:bookia_mobile/features/reservations/presentation/pages/reserve_page.dart';
import 'package:bookia_mobile/features/search/presentation/pages/search_results_page.dart';
import 'package:bookia_mobile/features/search/presentation/search_query.dart';
import 'package:bookia_mobile/features/splash/presentation/pages/splash_page.dart';
import 'package:bookia_mobile/features/stores/presentation/pages/store_detail_page.dart';
import 'package:bookia_mobile/features/stores/presentation/pages/stores_list_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route paths. The app starts on 01 Splash (then 02 the first time); screens 03, 04, 08, 12 and 15
/// hang from the bottom bar.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const locationPermission = '/onboarding/location';
  static const home = '/home';
  static const search = '/search';
  static const map = '/map';
  static const reservations = '/reservations';
  static const profile = '/profile';
  static const auth = '/auth';
  static const stores = '/stores';
  static const storeDetail = '/stores/:id';

  /// Screen 07, full screen over the bottom bar.
  static String book(String id) => '/books/$id';

  /// Location of screen 09 for [id].
  static String store(String id) => '/stores/$id';

  /// Screen 10 for [offerId] of [bookId].
  static String reserve(String bookId, String offerId) =>
      '/reserve/$bookId/$offerId';

  static const reservePattern = '/reserve/:bookId/:offerId';

  /// Screen 11 for an existing reservation of the signed-in reader.
  static String reservationReady(String id) => '/reservation/$id';

  static const reservationReadyPattern = '/reservation/:id';

  /// Login URL that returns to [next] (or to Perfil when it is null).
  static String signIn({String? next}) => Uri(
    path: auth,
    queryParameters: next == null ? null : {'next': next},
  ).toString();

  /// After signing in, only an internal reserve continuation is honored, so
  /// no arbitrary destination can be injected through the URL.
  static String afterAuth(String? next) =>
      next != null && _isContinuation(next) ? next : profile;

  static bool _isContinuation(String next) =>
      (next.startsWith('/reserve/') || next.startsWith('/reservation/')) &&
      !next.contains('://');

  static bool _needsReader(String path) =>
      path.startsWith('/reserve/') || path.startsWith('/reservation/');
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

Widget _results(GoRouterState state) => SearchResultsPage(
  key: ValueKey(state.uri),
  query: searchQueryFrom(state.uri.queryParameters),
);

/// Builds the app router. A new instance per call keeps tests isolated.
///
/// [session] and [refreshListenable] enable the reader guard of screens 10/11;
/// without them (unit tests) the routes behave as before. A cold deep link
/// into a protected route is redirected before the splash can restore a
/// stored token; the app normally starts on `/splash`.
GoRouter createRouter({
  String initialLocation = AppRoutes.home,
  SessionStatus Function()? session,
  Listenable? refreshListenable,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: refreshListenable,
  redirect: session == null
      ? null
      : (_, state) {
          if (!AppRoutes._needsReader(state.uri.path)) return null;
          if (session() is SignedInSession) return null;
          return AppRoutes.signIn(next: state.uri.toString());
        },
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
    GoRoute(
      path: AppRoutes.locationPermission,
      builder: (_, _) => const LocationPermissionPage(),
    ),
    GoRoute(path: AppRoutes.auth, builder: (_, _) => const AuthPage()),
    GoRoute(path: AppRoutes.stores, builder: (_, _) => const StoresListPage()),
    GoRoute(
      path: AppRoutes.storeDetail,
      builder: (_, state) => StoreDetailPage(
        key: ValueKey(state.pathParameters['id']),
        storeId: state.pathParameters['id']!,
      ),
    ),
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
    GoRoute(
      path: '/books/:id',
      builder: (_, state) =>
          BookDetailPage(bookId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.reservePattern,
      builder: (_, state) => ReservePage(
        key: ValueKey(state.uri),
        bookId: state.pathParameters['bookId']!,
        offerId: state.pathParameters['offerId']!,
      ),
    ),
    GoRoute(
      path: AppRoutes.reservationReadyPattern,
      builder: (_, state) => ReservationReadyPage(
        key: ValueKey(state.uri),
        reservationId: state.pathParameters['id']!,
        initial: state.extra is Reservation ? state.extra as Reservation : null,
        recovered: state.uri.queryParameters['recovered'] == '1',
      ),
    ),
  ],
);
