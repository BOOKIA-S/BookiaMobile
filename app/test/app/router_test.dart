import 'package:bookia_mobile/app/di.dart';
import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/search/presentation/pages/search_results_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../features/reservations/reservation_test_helpers.dart';
import '../helpers/fakes.dart';

void main() {
  Future<void> pumpRouter(WidgetTester tester, {String? at}) async {
    final router = createRouter(initialLocation: at ?? AppRoutes.home);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: offlineOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('bottom bar shows the five public tabs', (tester) async {
    await pumpRouter(tester);
    for (final label in ['Inicio', 'Buscar', 'Mapa', 'Reservas', 'Perfil']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('tapping a tab opens its page', (tester) async {
    await pumpRouter(tester);
    await tester.tap(find.text('Reservas'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mis reservas'), findsOneWidget);
  });

  testWidgets('a deep link selects the matching tab', (tester) async {
    await pumpRouter(tester, at: AppRoutes.map);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 2);
  });

  testWidgets('search remains available to visitors', (tester) async {
    await pumpRouter(tester);
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchResultsPage), findsOneWidget);
  });

  Future<GoRouter> pumpGuarded(
    WidgetTester tester, {
    required SessionStatus session,
    required String at,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final notifier = ValueNotifier<SessionStatus>(session);
    addTearDown(notifier.dispose);
    final container = ProviderContainer(
      overrides: [
        ...offlineOverrides(),
        reservableOfferSourceProvider.overrideWithValue(
          FakeReservableOfferSource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentSessionProvider.notifier).set(session);
    final router = createRouter(
      initialLocation: at,
      session: () => notifier.value,
      refreshListenable: notifier,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('a guest is redirected from screen 10 to login', (tester) async {
    final router = await pumpGuarded(
      tester,
      session: const GuestSession(),
      at: '/reserve/b1/o1',
    );

    expect(router.state.uri.path, AppRoutes.auth);
    expect(router.state.uri.queryParameters['next'], '/reserve/b1/o1');
  });

  testWidgets('a guest is redirected from screen 11 to login', (tester) async {
    final router = await pumpGuarded(
      tester,
      session: const GuestSession(),
      at: '/reservation/abc',
    );

    expect(router.state.uri.path, AppRoutes.auth);
    expect(router.state.uri.queryParameters['next'], '/reservation/abc');
  });

  testWidgets('a reader reaches screen 10', (tester) async {
    final router = await pumpGuarded(
      tester,
      session: const SignedInSession(name: 'Ana', role: 'reader'),
      at: '/reserve/b1/o1',
    );

    expect(router.state.uri.path, '/reserve/b1/o1');
    expect(find.text('Confirmar reserva'), findsOneWidget);
  });

  testWidgets('staff stays on screen 10 with an explanation', (tester) async {
    final router = await pumpGuarded(
      tester,
      session: const SignedInSession(name: 'Karol', role: 'store_owner'),
      at: '/reserve/b1/o1',
    );

    expect(router.state.uri.path, '/reserve/b1/o1');
    expect(
      find.text('Solo las cuentas de lector pueden reservar.'),
      findsOneWidget,
    );
  });

  testWidgets('the public home is not redirected', (tester) async {
    final router = await pumpGuarded(
      tester,
      session: const GuestSession(),
      at: AppRoutes.home,
    );

    expect(router.state.uri.path, AppRoutes.home);
  });
}
