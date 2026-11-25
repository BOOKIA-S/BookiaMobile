import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/favorites/favorite_book.dart';
import 'package:bookia_mobile/core/preferences/preferences_providers.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/features/profile/presentation/pages/favorites_page.dart';
import 'package:bookia_mobile/features/profile/presentation/pages/privacy_notice_page.dart';
import 'package:bookia_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:bookia_mobile/features/profile/presentation/providers.dart';
import 'package:bookia_mobile/features/profile/presentation/widgets/profile_activity_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_test_helpers.dart';

void main() {
  testWidgets('shows both counters and the unavailable alerts note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        preferencesStoreProvider.overrideWithValue(memoryPreferences()),
        activeReservationsProvider.overrideWith((_) => 2),
        favoriteBooksProvider.overrideWith(
          (_) async => List.generate(
            4,
            (i) => FavoriteBook(id: 'b$i', title: 'Libro $i'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentSessionProvider.notifier).set(testSession());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ProfileActivitySection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Alertas'), findsOneWidget);
    expect(
      find.textContaining('la API de alertas aún no existe'),
      findsOneWidget,
    );
  });

  testWidgets('one failed counter never becomes a fake zero', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        preferencesStoreProvider.overrideWithValue(memoryPreferences()),
        activeReservationsProvider.overrideWith(
          (_) => Future<int>.error(const NetworkFailure()),
        ),
        favoriteBooksProvider.overrideWith(
          (_) async => List.generate(
            3,
            (i) => FavoriteBook(id: 'b$i', title: 'Libro $i'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentSessionProvider.notifier).set(testSession());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ProfileActivitySection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No disponible'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('opens Mis reservas and Favoritos from the profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: profileOverrides(activeReservations: 1, favorites: 1),
    );
    addTearDown(container.dispose);
    container.read(currentSessionProvider.notifier).set(testSession());
    final router = createRouter(initialLocation: AppRoutes.profile);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mis reservas'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.reservations);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Favoritos'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.profileFavorites);
    expect(find.byType(FavoritesPage), findsOneWidget);
  });

  testWidgets('opens the privacy notice and returns to the profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: profileOverrides());
    addTearDown(container.dispose);
    container.read(currentSessionProvider.notifier).set(testSession());
    final router = createRouter(initialLocation: AppRoutes.profile);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Aviso de privacidad'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Aviso de privacidad'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.profilePrivacy);
    expect(find.byType(PrivacyNoticePage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.profile);
    expect(find.byType(ProfilePage), findsOneWidget);
  });
}
