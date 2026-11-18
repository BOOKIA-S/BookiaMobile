import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/pickup_code_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_test_helpers.dart';
import 'reserve_page_harness.dart';

const _reader = SignedInSession(name: 'Ana', role: 'reader');

FakeReservationRepository _uncertainRepository() {
  final repository = FakeReservationRepository();
  repository.onCreate = (_, _) async => throw const NetworkFailure();
  return repository;
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Confirmar reserva'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an uncertain POST shows the outcome card and blocks the form', (
    tester,
  ) async {
    final reservations = _uncertainRepository();
    await pumpReserve(tester, reservations: reservations, session: _reader);
    await _submit(tester);

    expect(find.text('Resultado incierto'), findsOneWidget);
    expect(find.text('Confirmar reserva'), findsNothing);
    expect(find.text('Volver a consultar'), findsOneWidget);
    expect(find.text('Descartar intento'), findsOneWidget);
    expect(reservations.createCalls, 1);
  });

  testWidgets('a recent match is offered as an existing reservation only', (
    tester,
  ) async {
    final reservations = _uncertainRepository();
    final (_, router) = await pumpReserve(
      tester,
      reservations: reservations,
      session: _reader,
    );
    await _submit(tester);
    reservations.onList = () async => [
      testReservation(
        id: 'abc4f7q',
        createdAt: DateTime.now().toUtc(),
        book: const ReservationBook(
          id: 'b1',
          title: 'Aura',
          author: 'Carlos Fuentes',
        ),
        store: const ReservationStore(
          id: 's1',
          name: 'Librería del Centro',
          address: 'Calle Juárez 10',
        ),
      ),
    ];

    await tester.tap(find.text('Volver a consultar'));
    await tester.pumpAndSettle();

    expect(find.text('Posibles reservas encontradas'), findsOneWidget);
    expect(find.text('Ver esta reserva'), findsOneWidget);
    expect(router.state.uri.path, '/reserve/b1/o1');
    expect(find.text('¡Libro apartado!'), findsNothing);

    await tester.tap(find.text('Ver esta reserva'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Reserva lista'), findsOneWidget);
    expect(find.text('Reserva encontrada'), findsOneWidget);
    expect(find.text('¡Libro apartado!'), findsNothing);
    expect(find.byType(PickupQr), findsOneWidget);
    expect(reservations.createCalls, 1);
  });

  testWidgets('an old match of the same offer is not offered', (tester) async {
    final reservations = _uncertainRepository();
    await pumpReserve(tester, reservations: reservations, session: _reader);
    await _submit(tester);
    reservations.onList = () async => [
      testReservation(
        quantity: 1,
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
      ),
    ];

    await tester.tap(find.text('Volver a consultar'));
    await tester.pumpAndSettle();

    expect(find.text('Ver esta reserva'), findsNothing);
    expect(find.text('Resultado incierto'), findsOneWidget);
    expect(find.text('Volver a consultar'), findsOneWidget);
  });

  testWidgets('several matches are all shown without choosing one', (
    tester,
  ) async {
    final reservations = _uncertainRepository();
    await pumpReserve(tester, reservations: reservations, session: _reader);
    await _submit(tester);
    reservations.onList = () async => [
      testReservation(id: 'r1', createdAt: DateTime.now().toUtc()),
      testReservation(id: 'r2', createdAt: DateTime.now().toUtc()),
    ];

    await tester.tap(find.text('Volver a consultar'));
    await tester.pumpAndSettle();

    expect(find.text('Ver esta reserva'), findsNWidgets(2));
    expect(find.text('Posibles reservas encontradas'), findsOneWidget);
  });

  testWidgets('an empty list does not claim that the reservation failed', (
    tester,
  ) async {
    final reservations = _uncertainRepository();
    await pumpReserve(tester, reservations: reservations, session: _reader);
    await _submit(tester);
    reservations.onList = () async => <Reservation>[];

    await tester.tap(find.text('Volver a consultar'));
    await tester.pumpAndSettle();

    expect(find.text('Resultado incierto'), findsOneWidget);
    expect(find.textContaining('No pudimos confirmar'), findsOneWidget);
    expect(find.textContaining('no existe'), findsNothing);
    expect(find.text('Volver a consultar'), findsOneWidget);
  });

  testWidgets('a failed verification keeps the attempt locked', (tester) async {
    final reservations = _uncertainRepository();
    await pumpReserve(tester, reservations: reservations, session: _reader);
    await _submit(tester);
    reservations.onList = () async => throw const ServerFailure();

    await tester.tap(find.text('Volver a consultar'));
    await tester.pumpAndSettle();

    expect(find.text('Resultado incierto'), findsOneWidget);
    expect(find.text('Volver a consultar'), findsOneWidget);
    expect(find.text('Confirmar reserva'), findsNothing);
    expect(reservations.createCalls, 1);
  });

  testWidgets(
    'discarding the attempt requires confirmation and keeps the notice',
    (tester) async {
      final reservations = _uncertainRepository();
      await pumpReserve(tester, reservations: reservations, session: _reader);
      await _submit(tester);

      await tester.tap(find.text('Descartar intento'));
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar la comprobación?'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Descartar intento'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('no se canceló'), findsOneWidget);
      expect(find.text('Confirmar reserva'), findsOneWidget);
      await _submit(tester);
      expect(reservations.createCalls, 2);
    },
  );

  testWidgets('changing quantity keeps the original attempt data', (
    tester,
  ) async {
    final reservations = _uncertainRepository();
    await pumpReserve(tester, reservations: reservations, session: _reader);
    await _submit(tester);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pumpAndSettle();

    expect(find.textContaining('Intento: 1 ejemplar'), findsOneWidget);
    expect(find.text('Confirmar reserva'), findsNothing);
    expect(reservations.createCalls, 1);
  });
}
