import 'dart:async';

import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:bookia_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:bookia_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:bookia_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:bookia_mobile/features/auth/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

class _Repository implements AuthRepository {
  String? action;
  int calls = 0;
  bool? staff;
  Future<AuthSession>? next;

  static final session = AuthSession(
    user: AuthUser(
      id: 'u1',
      email: 'a@b.mx',
      name: 'Ana',
      role: 'reader',
      storeId: null,
      mustChangePassword: false,
      createdAt: DateTime.utc(2026, 11, 9),
    ),
    token: 'secret',
    expiresInSeconds: 60,
  );

  @override
  Future<AuthSession> login(
    String email,
    String password, {
    bool staff = false,
  }) async {
    calls++;
    action = 'login';
    this.staff = staff;
    return next ?? session;
  }

  @override
  Future<AuthSession> register(
    String name,
    String email,
    String password,
  ) async {
    calls++;
    action = 'register';
    return next ?? session;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile tab validates, signs in as staff and logs out', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final repository = _Repository();
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
    final repository = _Repository();
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

  testWidgets(
    'loading disables submit and an error never displays credentials',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final pending = Completer<AuthSession>();
      final repository = _Repository()..next = pending.future;
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
      final repository = _Repository()..next = pending.future;
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
    final repository = _Repository()..next = pending.future;
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
    pending.complete(_Repository.session);
    await tester.pumpAndSettle();
    expect(find.text('Sesión iniciada: Ana'), findsOneWidget);
  });

  testWidgets(
    'failed account switch preserves visible session and stored token',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final repository = _Repository();
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
    },
  );
}
