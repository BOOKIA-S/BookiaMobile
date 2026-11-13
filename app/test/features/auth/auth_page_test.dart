import 'dart:async';

import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:bookia_mobile/features/auth/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile tab validates, signs in as staff and logs out', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final repository = FakeAuthRepository();
    final router = createRouter(initialLocation: AppRoutes.profile);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Buscar no requiere cuenta.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un correo válido'), findsOneWidget);
    expect(repository.action, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      'a@b.mx',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'password123',
    );
    await tester.tap(find.text('Acceso staff'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(repository.action, 'login');
    expect(repository.staff, isTrue);
    expect(find.text('Sesión iniciada: Ana'), findsOneWidget);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsWidgets);
  });

  testWidgets('register requires name and a password of 8 to 200 characters', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final repository = FakeAuthRepository();
    final router = createRouter(initialLocation: AppRoutes.auth);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      'a@b.mx',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      '1234567',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu nombre'), findsOneWidget);
    expect(
      find.text('La contraseña debe tener entre 8 y 200 caracteres'),
      findsOneWidget,
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Ana');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(repository.action, 'register');
  });

  testWidgets('login sends existing passwords without registration limits', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final repository = FakeAuthRepository();
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
      'short',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    expect(find.text('Sesión iniciada: Ana'), findsOneWidget);
  });

  testWidgets(
    'loading disables submit and an error never displays credentials',
    (tester) async {
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
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(repository.calls, 1);
      pending.completeError(StateError('password123 secret'));
      await tester.pumpAndSettle();
      expect(
        find.text('No pudimos completar el acceso. Intenta de nuevo.'),
        findsOneWidget,
      );
      expect(find.textContaining('secret'), findsNothing);
      repository.next = null;
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Sesión iniciada: Ana'), findsOneWidget);
    },
  );
}
