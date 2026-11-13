import 'dart:async';

import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/features/splash/domain/entities/session_status.dart';
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

  Future<GoRouter> pumpSplash(
    WidgetTester tester,
    SessionRepository repo,
  ) async {
    final router = createRouter(initialLocation: AppRoutes.splash);
    addTearDown(router.dispose);
    container = ProviderContainer(
      overrides: [
        ...offlineOverrides(),
        sessionRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    return router;
  }

  testWidgets('shows the logo while checking, then opens Inicio as guest', (
    tester,
  ) async {
    final pending = Completer<bool>();
    final repo = _MockSessionRepository();
    when(repo.hasStoredToken).thenAnswer((_) => pending.future);
    final router = await pumpSplash(tester, repo);

    expect(find.text('Libros de Huauchinango en tu mano'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(false);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.home);
    expect(container.read(currentSessionProvider), isA<GuestSession>());
  });

  testWidgets('a valid session is published before opening Inicio', (
    tester,
  ) async {
    final repo = _MockSessionRepository();
    when(repo.hasStoredToken).thenAnswer((_) async => true);
    when(repo.fetchCurrentUser).thenAnswer(
      (_) async => const SignedInSession(name: 'Ana', role: 'reader'),
    );
    final router = await pumpSplash(tester, repo);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.home);
    final session = container.read(currentSessionProvider);
    expect(session, isA<SignedInSession>());
    expect((session as SignedInSession).name, 'Ana');
  });
}
