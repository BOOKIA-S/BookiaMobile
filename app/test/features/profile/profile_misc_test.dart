import 'package:bookia_mobile/core/favorites/favorite_book.dart';
import 'package:bookia_mobile/core/location/location_providers.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/core/preferences/preferences_providers.dart';
import 'package:bookia_mobile/core/preferences/preferences_store.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/profile/presentation/pages/favorites_page.dart';
import 'package:bookia_mobile/features/profile/presentation/pages/privacy_notice_page.dart';
import 'package:bookia_mobile/features/profile/presentation/providers.dart';
import 'package:bookia_mobile/features/profile/presentation/widgets/profile_preferences_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';
import 'profile_test_helpers.dart';

void main() {
  testWidgets('the privacy notice describes the real behaviour and SEG-04', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: PrivacyNoticePage()));
    expect(find.text('Aviso de privacidad'), findsOneWidget);
    expect(find.textContaining('SEG-04'), findsWidgets);
    expect(find.textContaining('Borrador técnico'), findsOneWidget);
    expect(find.textContaining('No se inventan aquí'), findsOneWidget);
    expect(find.textContaining('responsable legal'), findsOneWidget);
  });

  testWidgets('favorites show the real fields and the empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        favoriteBooksProvider.overrideWith(
          (_) async => const [
            FavoriteBook(
              id: 'b1',
              title: 'Aura',
              author: 'Carlos Fuentes',
              genre: 'Novela',
              publisher: 'Era',
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentSessionProvider.notifier).set(testSession());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FavoritesPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aura'), findsOneWidget);
    expect(find.textContaining('Carlos Fuentes'), findsOneWidget);
    expect(find.textContaining('Novela'), findsOneWidget);
  });

  testWidgets('favorites show an empty state', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final empty = ProviderContainer(
      overrides: [
        favoriteBooksProvider.overrideWith((_) async => <FavoriteBook>[]),
      ],
    );
    addTearDown(empty.dispose);
    empty.read(currentSessionProvider.notifier).set(testSession());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: empty,
        child: const MaterialApp(home: FavoritesPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Aún no tienes libros favoritos'),
      findsOneWidget,
    );
  });

  testWidgets('favorites show an error and a retry', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final error = ProviderContainer(
      overrides: [
        favoriteBooksProvider.overrideWith((_) async => throw profileFailure),
      ],
    );
    addTearDown(error.dispose);
    error.read(currentSessionProvider.notifier).set(testSession());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: error,
        child: const MaterialApp(home: FavoritesPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(profileFailure.message), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('disabling location clears the position and never asks again', (
    tester,
  ) async {
    final store = MemoryPreferencesStore({PreferenceKeys.useLocation: true});
    final location = MockLocationService();
    when(location.requestAccess)
        .thenAnswer((_) async => LocationAccess.granted);
    when(location.currentPosition)
        .thenAnswer((_) async => (lat: 20.17, lng: -98.05));
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        locationServiceProvider.overrideWithValue(location),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ProfilePreferencesSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(await store.readBool(PreferenceKeys.useLocation), isFalse);
    expect(container.read(currentPositionProvider), isNull);
    expect(
      await container.read(currentPositionProvider.notifier).refresh(),
      isNull,
    );
    verifyNever(location.currentPosition);
  });

  testWidgets('enabling location asks permission and refreshes the position', (
    tester,
  ) async {
    final store = MemoryPreferencesStore({PreferenceKeys.useLocation: false});
    final location = MockLocationService();
    when(location.requestAccess)
        .thenAnswer((_) async => LocationAccess.granted);
    when(location.currentPosition)
        .thenAnswer((_) async => (lat: 20.17, lng: -98.05));
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        locationServiceProvider.overrideWithValue(location),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ProfilePreferencesSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(await store.readBool(PreferenceKeys.useLocation), isTrue);
    verify(location.requestAccess).called(1);
    expect(container.read(currentPositionProvider), (lat: 20.17, lng: -98.05));
  });

  testWidgets('a guest favorites page does not call the API', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(currentSessionProvider.notifier).set(const GuestSession());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FavoritesPage()),
      ),
    );
    expect(find.text('Inicia sesión para ver tus favoritos.'), findsOneWidget);
  });
}
