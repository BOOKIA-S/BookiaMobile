import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/location/location_providers.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/onboarding/presentation/providers.dart';
import 'package:bookia_mobile/features/splash/domain/repositories/session_repository.dart';
import 'package:bookia_mobile/features/splash/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late ProviderContainer container;
  late MockLocationService location;
  late MockOnboardingRepository onboarding;

  setUp(() {
    location = MockLocationService();
    onboarding = MockOnboardingRepository();
    when(location.checkAccess).thenAnswer((_) async => LocationAccess.denied);
    when(location.currentPosition).thenAnswer((_) async => null);
    when(onboarding.wasLocationAsked).thenAnswer((_) async => false);
    when(onboarding.markLocationAsked).thenAnswer((_) async {});
  });

  Future<GoRouter> pump(WidgetTester tester, String initialLocation) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = _MockSessionRepository();
    when(session.hasStoredToken).thenAnswer((_) async => false);
    final router = createRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);
    container = ProviderContainer(
      overrides: [
        ...offlineOverrides(location: false),
        sessionRepositoryProvider.overrideWithValue(session),
        locationServiceProvider.overrideWithValue(location),
        onboardingRepositoryProvider.overrideWithValue(onboarding),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('the first start goes from 01 Splash to 02', (tester) async {
    final router = await pump(tester, AppRoutes.splash);

    expect(router.state.uri.path, AppRoutes.locationPermission);
    expect(find.text('Encuentra la librería más cercana'), findsOneWidget);
    expect(find.textContaining('Nunca la guardamos'), findsOneWidget);
  });

  testWidgets('with the permission granted it skips 02 and loads the '
      'position', (tester) async {
    when(location.checkAccess).thenAnswer((_) async => LocationAccess.granted);
    when(location.currentPosition)
        .thenAnswer((_) async => (lat: 20.17, lng: -98.05));
    final router = await pump(tester, AppRoutes.splash);

    expect(router.state.uri.path, AppRoutes.home);
    expect(container.read(currentPositionProvider), (lat: 20.17, lng: -98.05));
  });

  testWidgets('Permitir ubicación asks, publishes the position and opens '
      'Inicio', (tester) async {
    when(location.requestAccess)
        .thenAnswer((_) async => LocationAccess.granted);
    when(location.currentPosition)
        .thenAnswer((_) async => (lat: 20.17, lng: -98.05));
    final router = await pump(tester, AppRoutes.locationPermission);

    await tester.tap(find.text('Permitir ubicación'));
    await tester.pumpAndSettle();

    verify(onboarding.markLocationAsked).called(1);
    expect(router.state.uri.path, AppRoutes.home);
    expect(container.read(currentPositionProvider), (lat: 20.17, lng: -98.05));
  });

  testWidgets('a blocked permission explains how to unblock it', (
    tester,
  ) async {
    when(location.requestAccess)
        .thenAnswer((_) async => LocationAccess.deniedForever);
    final router = await pump(tester, AppRoutes.locationPermission);

    await tester.tap(find.text('Permitir ubicación'));
    await tester.pump();

    expect(find.textContaining('Puedes activarla en Ajustes'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.home);
    expect(container.read(currentPositionProvider), isNull);
  });

  testWidgets('Ahora no opens Inicio without asking', (tester) async {
    final router = await pump(tester, AppRoutes.locationPermission);

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    verify(onboarding.markLocationAsked).called(1);
    verifyNever(location.requestAccess);
    expect(router.state.uri.path, AppRoutes.home);
  });
}
