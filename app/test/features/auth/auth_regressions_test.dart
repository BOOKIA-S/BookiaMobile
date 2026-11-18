import 'dart:async';
import 'dart:typed_data';

import 'package:bookia_mobile/app/di.dart';
import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/core/storage/token_storage.dart';
import 'package:bookia_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:bookia_mobile/features/auth/presentation/providers.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/failing_secure_storage.dart';
import '../reservations/reservation_test_helpers.dart';
import 'auth_test_helpers.dart';

/// POST /reservations always answers 401, like an expired token.
class _UnauthorizedAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    calls++;
    return ResponseBody.fromString(
      '{"message":"Invalid session"}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a second login while the first is pending sends one request', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final pending = Completer<Object?>();
    final repository = FakeAuthRepository()
      ..next = pending.future.then((_) => FakeAuthRepository.session);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);

    final first = controller.login('a@b.mx', 'password123');
    final second = controller.login('a@b.mx', 'password123');
    expect(repository.calls, 1);

    pending.complete();
    await first;
    await second;
    expect(container.read(currentSessionProvider), isA<SignedInSession>());
  });

  test('a token that cannot be persisted does not sign the user in', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        tokenStorageProvider.overrideWithValue(
          const TokenStorage(storage: FailingSecureStorage('write')),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login('a@b.mx', 'password123');

    expect(container.read(authControllerProvider).hasError, isTrue);
    expect(container.read(currentSessionProvider), isA<GuestSession>());
  });

  test(
    'logout surfaces a secure-storage failure instead of faking it',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tokenStorageProvider.overrideWithValue(
            const TokenStorage(storage: FailingSecureStorage('delete')),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(authControllerProvider.notifier);
      await controller.login('a@b.mx', 'password123');
      expect(container.read(currentSessionProvider), isA<SignedInSession>());

      // Known limitation: the interceptor and the controller cannot clear a
      // token whose delete failed, so the session stays signed in and the UI
      // must show the error. Fixing this needs a storage contract change.
      await expectLater(controller.logout(), throwsA(isA<StateError>()));
      expect(container.read(currentSessionProvider), isA<SignedInSession>());
    },
  );

  testWidgets('a 401 while reserving clears the session and asks to log in', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final adapter = _UnauthorizedAdapter();
    final container = ProviderContainer(
      overrides: [
        reservableOfferSourceProvider.overrideWithValue(
          FakeReservableOfferSource(),
        ),
        apiBaseUrlProvider.overrideWithValue('https://bookia.test/api'),
        dioProvider.overrideWithValue(Dio()..httpClientAdapter = adapter),
      ],
    );
    addTearDown(container.dispose);
    await container.read(tokenStorageProvider).saveToken('expired-token');
    container
        .read(currentSessionProvider.notifier)
        .set(const SignedInSession(name: 'Ana', role: 'reader'));
    final router = createRouter(initialLocation: '/reserve/b1/o1');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar reserva'));
    await tester.pumpAndSettle();

    expect(adapter.calls, 1);
    expect(container.read(currentSessionProvider), isA<GuestSession>());
    expect(await container.read(tokenStorageProvider).readToken(), isNull);
    expect(
      find.text('Inicia sesión para reservar este libro.'),
      findsOneWidget,
    );
    expect(find.text('¡Libro apartado!'), findsNothing);
  });

  testWidgets('the reserve button is disabled while the request is pending', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pending = Completer<Reservation>();
    final reservations = FakeReservationRepository();
    reservations.onCreate = (_, _) => pending.future;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        reservableOfferSourceProvider.overrideWithValue(
          FakeReservableOfferSource(),
        ),
        reservationRepositoryProvider.overrideWithValue(reservations),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(currentSessionProvider.notifier)
        .set(const SignedInSession(name: 'Ana', role: 'reader'));
    final router = createRouter(initialLocation: '/reserve/b1/o1');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar reserva'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(FilledButton));
    expect(reservations.createCalls, 1);

    pending.completeError(
      const ConflictFailure('Ya no hay suficientes ejemplares.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ya no hay suficientes ejemplares.'), findsOneWidget);
  });
}
