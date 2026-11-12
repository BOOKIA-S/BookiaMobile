import 'dart:async';

import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:bookia_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:bookia_mobile/features/auth/presentation/providers.dart';
import 'package:bookia_mobile/features/splash/domain/entities/session_status.dart';
import 'package:bookia_mobile/features/splash/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import 'auth_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (failure, register, expected) in [
    (const UnauthorizedFailure(), false, 'Correo o contraseña incorrectos.'),
    (
      const ConflictFailure('Email is already registered'),
      true,
      'Este correo ya está registrado.',
    ),
    (
      const RateLimitFailure(),
      false,
      'Demasiados intentos. Espera unos minutos.',
    ),
  ]) {
    testWidgets('shows ${failure.runtimeType} in Spanish', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final pending = Completer<AuthSession>();
      final repository = FakeAuthRepository()..next = pending.future;
      final router = createRouter(initialLocation: AppRoutes.auth);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      if (register) {
        await tester.tap(find.text('Crear cuenta'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre'),
          'Ana',
        );
      }
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'a@b.mx',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          register ? 'Crear cuenta' : 'Iniciar sesión',
        ),
      );
      pending.completeError(failure);
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
      expect(find.textContaining('Email is already registered'), findsNothing);
    });
  }

  testWidgets('two taps send one request, then render the session', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final pending = Completer<AuthSession>();
    final repository = FakeAuthRepository()..next = pending.future;
    final router = createRouter(initialLocation: AppRoutes.auth);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      'a@b.mx',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'password123',
    );
    final submit = find.widgetWithText(FilledButton, 'Iniciar sesión');
    await tester.tap(submit);
    await tester.tap(submit);
    expect(repository.calls, 1);
    pending.complete(FakeAuthRepository.session);
    await tester.pumpAndSettle();
    expect(find.text('Sesión iniciada: Ana'), findsOneWidget);
  });

  testWidgets(
    'failed account switch preserves visible session and stored token',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          ...offlineOverrides(),
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(authControllerProvider.notifier);
      await controller.login('a@b.mx', 'password123');
      final router = createRouter(initialLocation: AppRoutes.profile);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sesión iniciada: Ana'), findsOneWidget);
      repository.next = Future<AuthSession>.error(const UnauthorizedFailure());
      await controller.login('other@b.mx', 'wrong-password');
      await tester.pumpAndSettle();
      expect(find.text('Sesión iniciada: Ana'), findsOneWidget);
      expect(await container.read(tokenStorageProvider).readToken(), 'secret');
      expect(container.read(currentSessionProvider), isA<SignedInSession>());
    },
  );
}
