import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:bookia_mobile/features/reservations/data/repositories/reservation_repository_impl.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';
import 'package:bookia_mobile/features/reservations/presentation/pages/my_reservations_page.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/expiry_countdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';
import 'reservation_test_helpers.dart';

final now = DateTime.utc(2026, 11, 18, 12);

const aura = ReservationBook(id: 'b1', title: 'Aura', author: 'Carlos Fuentes');
const centro = ReservationStore(id: 's1', name: 'Librería del Centro');

Reservation mine(String id, ReservationStatus status, {int hoursLeft = 30}) =>
    testReservation(
      id: id,
      status: status,
      quantity: 2,
      expiresAt: now.add(Duration(hours: hoursLeft)),
      book: aura,
      store: centro,
    );

void main() {
  group('remainingLabel', () {
    test('shows days, hours or minutes left', () {
      expect(remainingLabel(const Duration(hours: 27)), 'Vence en 1 d 3 h');
      expect(
        remainingLabel(const Duration(hours: 2, minutes: 15)),
        'Vence en 2 h 15 min',
      );
      expect(remainingLabel(const Duration(minutes: 5)), 'Vence en 5 min');
      expect(remainingLabel(const Duration(seconds: 20)), 'Vence en 1 min');
      expect(remainingLabel(Duration.zero), 'Vencida');
    });
  });

  group('cancel in the repository', () {
    ReservationRepositoryImpl repo(FakeHttpAdapter adapter) =>
        ReservationRepositoryImpl(
          ReservationRemoteDataSource(fakeApiClient(adapter)),
        );

    test('PATCH /reservations/:id/cancel returns the cancelled one', () async {
      final adapter = FakeHttpAdapter(200, {
        '_id': 'r1',
        'user_id': 'u1',
        'offer_id': 'o1',
        'store_id': 's1',
        'book_id': 'b1',
        'price': 129,
        'quantity': 1,
        'status': 'cancelada',
        'expires_at': '2026-11-19T20:00:00.000Z',
        'created_at': '2026-11-17T20:00:00.000Z',
        'updated_at': '2026-11-18T12:00:00.000Z',
      });
      final cancelled = await repo(adapter).cancel('r1');
      expect(adapter.last!.method, 'PATCH');
      expect(adapter.last!.uri.path, '/api/reservations/r1/cancel');
      expect(cancelled.status, isA<Cancelled>());
    });

    test('409 explains it can no longer be cancelled', () {
      final adapter = FakeHttpAdapter(409, {'message': 'Not active'});
      expect(
        repo(adapter).cancel('r1'),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.message,
            'message',
            'Esta reserva ya no se puede cancelar.',
          ),
        ),
      );
    });
  });

  group('screen 12', () {
    late FakeReservationRepository repo;
    setUp(() => repo = FakeReservationRepository());

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [reservationRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(home: MyReservationsPage(now: () => now)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('splits active and history with countdown and actions', (
      tester,
    ) async {
      repo.onList = () async => [
        mine('aaaaa1', const Pending()),
        mine('bbbbb2', const Confirmed(), hoursLeft: 3),
        mine('ccccc3', const Delivered()),
      ];
      await pump(tester);

      expect(find.text('Activas (2)'), findsOneWidget);
      expect(find.text('BK-AAA1'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Vence en 1 d 6 h'), findsOneWidget);
      expect(find.text('Vence en 3 h 0 min'), findsOneWidget);
      expect(find.text('Cancelar'), findsNWidgets(2));
      expect(find.text('Entregada'), findsNothing);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();
      expect(find.text('Entregada'), findsOneWidget);
      expect(find.text('Cancelar'), findsNothing);
    });

    testWidgets('cancel asks first, then reloads the list', (tester) async {
      var cancelled = false;
      repo.onList = () async => [
        mine('aaaaa1', cancelled ? const Cancelled() : const Pending()),
      ];
      repo.onCancel = (id) async {
        cancelled = true;
        return mine(id, const Cancelled());
      };
      await pump(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cancelar la reserva?'), findsOneWidget);
      await tester.tap(find.text('Sí, cancelar'));
      await tester.pumpAndSettle();

      expect(repo.cancelled, ['aaaaa1']);
      expect(find.text('Reserva BK-AAA1 cancelada.'), findsOneWidget);
      expect(find.text('Activas (0)'), findsOneWidget);
      expect(find.textContaining('No tienes reservas activas'), findsOneWidget);
    });

    testWidgets('saying No keeps the reservation', (tester) async {
      repo.onList = () async => [mine('aaaaa1', const Pending())];
      await pump(tester);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(repo.cancelled, isEmpty);
      expect(find.text('Activas (1)'), findsOneWidget);
    });

    testWidgets('without a session it offers to sign in', (tester) async {
      repo.onList = () => Future.error(const UnauthorizedFailure());
      await pump(tester);
      expect(find.text('Inicia sesión para ver tus reservas.'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });
  });
}
