import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/pickup_code_card.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/quantity_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/auth_test_helpers.dart';
import 'reservation_test_helpers.dart';
import 'reserve_page_harness.dart';

const _reader = SignedInSession(name: 'Ana', role: 'reader');

void main() {
  testWidgets('screen 10 shows the offer, quantity and the notes', (
    tester,
  ) async {
    await pumpReserve(tester, session: _reader);

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
    await pumpReserve(tester, session: _reader);

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
    await pumpReserve(tester, offer: testOffer(stock: 2), session: _reader);

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
    final (_, router) = await pumpReserve(tester);

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
    await pumpReserve(
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

  testWidgets('a sold-out offer hides the selector and cannot be confirmed', (
    tester,
  ) async {
    await pumpReserve(tester, offer: testOffer(stock: 0), session: _reader);

    expect(find.text('Agotado'), findsOneWidget);
    expect(find.byType(QuantitySelector), findsNothing);
    expect(find.text('Máximo 0 por reserva'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Confirmar reserva'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('a stock of one keeps the selector available', (tester) async {
    await pumpReserve(tester, offer: testOffer(stock: 1), session: _reader);

    expect(find.byType(QuantitySelector), findsOneWidget);
    expect(find.text('Máximo 1 por reserva'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'a successful reservation opens screen 11 without posting again',
    (tester) async {
      const book = ReservationBook(
        id: 'b1',
        title: 'Aura',
        author: 'Carlos Fuentes',
      );
      const store = ReservationStore(
        id: 's1',
        name: 'Librería del Centro',
        address: 'Calle Juárez 10',
      );
      final reservations = FakeReservationRepository();
      reservations.onCreate = (_, quantity) async => testReservation(
        id: 'abc4f7q',
        price: 99,
        quantity: quantity,
        book: book,
        store: store,
      );
      reservations.onList = () async => [
        testReservation(
          id: 'abc4f7q',
          price: 99,
          quantity: 2,
          book: book,
          store: store,
        ),
      ];
      await pumpReserve(tester, reservations: reservations, session: _reader);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar reserva'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Reserva lista'), findsOneWidget);
      expect(find.text('¡Libro apartado!'), findsOneWidget);
      expect(find.text('BK-4F7Q'), findsOneWidget);
      expect(tester.widget<PickupQr>(find.byType(PickupQr)).data, 'abc4f7q');
      expect(find.text(r'$198.00'), findsOneWidget);
      expect(reservations.lastQuantity, 2);
      expect(reservations.createCalls, 1);
      await tester.pumpAndSettle();
      expect(reservations.createCalls, 1);
    },
  );

  testWidgets('a 409 shows the insufficient-copies message', (tester) async {
    final reservations = FakeReservationRepository()
      ..onCreate = (_, _) async =>
          throw const ConflictFailure('Ya no hay suficientes ejemplares.');
    await pumpReserve(tester, reservations: reservations, session: _reader);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar reserva'));
    await tester.pumpAndSettle();

    expect(find.text('Ya no hay suficientes ejemplares.'), findsOneWidget);
  });

  testWidgets('book detail sends a guest to login for that offer', (
    tester,
  ) async {
    final (_, router) = await pumpReserve(tester, location: '/books/b1');

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
    final (_, router) = await pumpReserve(
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
    expect(AppRoutes.afterAuth('/reservation/abc'), '/reservation/abc');
  });
}
