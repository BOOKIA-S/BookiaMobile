import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/auth/presentation/providers.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/presentation/providers.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_test_helpers.dart';
import 'reservation_test_helpers.dart';

Future<(ProviderContainer, GoRouter)> _pump(
  WidgetTester tester, {
  String location = '/reserve/b1/o1',
  Book? book,
  FakeReservationRepository? reservations,
  SessionStatus session = const GuestSession(),
  FakeAuthRepository? auth,
}) async {
  FlutterSecureStorage.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      bookRepositoryProvider.overrideWithValue(FakeBookRepository(book)),
      reservationRepositoryProvider.overrideWithValue(
        reservations ?? FakeReservationRepository(),
      ),
      if (auth != null) authRepositoryProvider.overrideWithValue(auth),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentSessionProvider.notifier).set(session);
  final router = createRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (container, router);
}

const _reader = SignedInSession(name: 'Ana', role: 'reader');

void main() {
  testWidgets('screen 10 shows the offer, quantity and the notes', (
    tester,
  ) async {
    await _pump(tester, session: _reader);

    expect(find.text('Reservar'), findsOneWidget);
    expect(find.text('Aura'), findsOneWidget);
    expect(find.text('Librería del Centro'), findsOneWidget);
    expect(find.text(r'$129.00'), findsNWidgets(2));
    expect(find.text('6 disponibles'), findsOneWidget);
    expect(find.text('Máximo 5 por reserva'), findsOneWidget);
    expect(find.textContaining('48 horas'), findsOneWidget);
    expect(find.textContaining('10 reservas activas'), findsOneWidget);
    expect(
      find.text('Sin pago en línea. Puedes cancelar cuando quieras'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Confirmar reserva'),
      findsOneWidget,
    );
  });

  testWidgets('the quantity controls update the total and respect the limits', (
    tester,
  ) async {
    await _pump(tester, session: _reader);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.remove));
    await tester.pumpAndSettle();
    expect(find.text(r'$129.00'), findsNWidgets(2));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pumpAndSettle();
    expect(find.text(r'$258.00'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.pumpAndSettle();
    }
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
          .onPressed,
      isNull,
    );
  });

  testWidgets('the maximum is the stock when it is lower than five', (
    tester,
  ) async {
    await _pump(tester, book: testBook(stock: 2), session: _reader);

    expect(find.text('Máximo 2 por reserva'), findsOneWidget);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
          .onPressed,
      isNull,
    );
  });

  testWidgets('a guest is sent to login and returns to the same offer', (
    tester,
  ) async {
    final (_, router) = await _pump(tester);

    expect(
      find.text('Inicia sesión para reservar este libro.'),
      findsOneWidget,
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Iniciar sesión para reservar'),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.auth);
    expect(
      router.state.uri.queryParameters['next'],
      AppRoutes.reserve('b1', 'o1'),
    );
  });

  testWidgets('store staff get an explanation, not a login loop', (
    tester,
  ) async {
    await _pump(
      tester,
      session: const SignedInSession(name: 'Karol', role: 'store_owner'),
    );

    expect(
      find.text('Solo las cuentas de lector pueden reservar.'),
      findsOneWidget,
    );
    expect(find.text('Confirmar reserva'), findsNothing);
    expect(find.text('Iniciar sesión para reservar'), findsNothing);
  });

  testWidgets('a sold-out offer cannot be confirmed', (tester) async {
    await _pump(tester, book: testBook(stock: 0), session: _reader);

    expect(find.text('Agotado'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Confirmar reserva'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('a successful reservation shows the values sent by the server', (
    tester,
  ) async {
    final reservations = FakeReservationRepository()
      ..onCreate = (_, quantity) async =>
          testReservation(price: 99, quantity: quantity);
    await _pump(tester, reservations: reservations, session: _reader);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar reserva'));
    await tester.pumpAndSettle();

    expect(find.text('Reserva creada'), findsOneWidget);
    expect(find.text(r'$198.00'), findsOneWidget);
    expect(reservations.lastQuantity, 2);
  });

  testWidgets('a 409 shows the insufficient-copies message', (tester) async {
    final reservations = FakeReservationRepository()
      ..onCreate = (_, _) async =>
          throw const ConflictFailure('Ya no hay suficientes ejemplares.');
    await _pump(tester, reservations: reservations, session: _reader);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar reserva'));
    await tester.pumpAndSettle();

    expect(find.text('Ya no hay suficientes ejemplares.'), findsOneWidget);
  });

  testWidgets('book detail sends a guest to login for that offer', (
    tester,
  ) async {
    final (_, router) = await _pump(tester, location: '/books/b1');

    await tester.tap(find.widgetWithText(TextButton, 'Reservar'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.auth);
    expect(
      router.state.uri.queryParameters['next'],
      AppRoutes.reserve('b1', 'o1'),
    );
  });

  testWidgets('after login the reader continues with the pending reserve', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final (_, router) = await _pump(
      tester,
      location: '/auth?next=/reserve/b1/o1',
      auth: auth,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      'a@b.mx',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(auth.action, 'login');
    expect(router.state.uri.path, '/reserve/b1/o1');
    expect(find.text('Confirmar reserva'), findsOneWidget);
  });

  test('only an internal reserve continuation is honored after login', () {
    expect(AppRoutes.afterAuth(null), AppRoutes.profile);
    expect(AppRoutes.afterAuth('/profile'), AppRoutes.profile);
    expect(
      AppRoutes.afterAuth('https://evil.test/reserve/1'),
      AppRoutes.profile,
    );
    expect(AppRoutes.afterAuth('//evil.test/reserve'), AppRoutes.profile);
    expect(AppRoutes.afterAuth('/reserve/b1/o1'), '/reserve/b1/o1');
  });
}
