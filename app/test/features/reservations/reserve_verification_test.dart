import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_controller.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_test_helpers.dart';
import 'reserve_controller_harness.dart';

void main() {
  test('verify shows a recent match only as a candidate', () async {
    final reservations = FakeReservationRepository();
    final container = reserveContainer(reservations: reservations);
    await makeUncertain(container);
    reservations.onList = () async => [
      testReservation(id: 'r9', quantity: 2, createdAt: DateTime.now().toUtc()),
    ];

    await container
        .read(reserveControllerProvider(reserveKey).notifier)
        .verify();

    final state = stateOf(container);
    expect(state.status, isA<ReserveCandidates>());
    expect(state.created, isNull);
    expect(state.candidates, hasLength(1));
    expect(state.candidates.single.id, 'r9');
    expect(reservations.createCalls, 1);
  });

  test('an older reservation of the same offer is not a candidate', () async {
    final reservations = FakeReservationRepository();
    final container = reserveContainer(reservations: reservations);
    await makeUncertain(container);
    reservations.onList = () async => [
      testReservation(
        id: 'old',
        quantity: 2,
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
      ),
    ];

    await container
        .read(reserveControllerProvider(reserveKey).notifier)
        .verify();

    final state = stateOf(container);
    expect(state.status, isA<ReserveUncertain>());
    expect(state.created, isNull);
    expect(state.candidates, isEmpty);
    expect(state.canVerify, isTrue);
    expect(state.isLocked, isTrue);
    expect(reservations.createCalls, 1);
  });

  test('a reservation with another quantity is not a candidate', () async {
    final reservations = FakeReservationRepository();
    final container = reserveContainer(reservations: reservations);
    await makeUncertain(container);
    reservations.onList = () async => [
      testReservation(
        id: 'other-quantity',
        quantity: 1,
        createdAt: DateTime.now().toUtc(),
      ),
    ];

    await container
        .read(reserveControllerProvider(reserveKey).notifier)
        .verify();

    expect(stateOf(container).candidates, isEmpty);
    expect(stateOf(container).status, isA<ReserveUncertain>());
  });

  test('multiple candidates are all shown without choosing one', () async {
    final reservations = FakeReservationRepository();
    final container = reserveContainer(reservations: reservations);
    await makeUncertain(container);
    reservations.onList = () async => [
      testReservation(id: 'r1', quantity: 2, createdAt: DateTime.now().toUtc()),
      testReservation(id: 'r2', quantity: 2, createdAt: DateTime.now().toUtc()),
    ];

    await container
        .read(reserveControllerProvider(reserveKey).notifier)
        .verify();

    expect(stateOf(container).candidates, hasLength(2));
    expect(stateOf(container).created, isNull);
  });

  test('an empty or failed list does not prove the POST failed', () async {
    final reservations = FakeReservationRepository();
    final container = reserveContainer(reservations: reservations);
    await makeUncertain(container);
    reservations.onList = () async => <Reservation>[];

    await container
        .read(reserveControllerProvider(reserveKey).notifier)
        .verify();

    expect(stateOf(container).status, isA<ReserveUncertain>());
    expect(stateOf(container).failure, isA<ConflictFailure>());
    expect(stateOf(container).canVerify, isTrue);
    expect(stateOf(container).created, isNull);

    reservations.onList = () async => throw const ServerFailure();
    await container
        .read(reserveControllerProvider(reserveKey).notifier)
        .verify();
    expect(stateOf(container).failure, isA<ServerFailure>());
    expect(stateOf(container).isLocked, isTrue);
    expect(reservations.createCalls, 1);
  });

  test('changing quantity does not erase the uncertain attempt', () async {
    final reservations = FakeReservationRepository();
    final container = reserveContainer(reservations: reservations);
    await makeUncertain(container);
    final controller = container.read(
      reserveControllerProvider(reserveKey).notifier,
    );

    controller.decrement();
    expect(stateOf(container).quantity, 1);
    expect(stateOf(container).attempt!.quantity, 2);
    await controller.submit();
    expect(reservations.createCalls, 1);
  });

  test(
    'a lost response after an effective creation does not POST again',
    () async {
      final reservations = FakeReservationRepository();
      final serverCreated = <Reservation>[];
      reservations.onCreate = (offerId, quantity) async {
        serverCreated.add(
          testReservation(
            id: 'lost',
            quantity: quantity,
            createdAt: DateTime.now().toUtc(),
          ),
        );
        throw const NetworkFailure();
      };
      final container = reserveContainer(reservations: reservations);
      signIn(container);
      await container.read(reserveControllerProvider(reserveKey).future);
      final controller = container.read(
        reserveControllerProvider(reserveKey).notifier,
      );
      await controller.submit();
      reservations.onList = () async => serverCreated;

      await controller.verify();

      final state = stateOf(container);
      expect(state.status, isA<ReserveCandidates>());
      expect(state.created, isNull);
      expect(state.candidates.single.id, 'lost');
      await controller.submit();
      expect(reservations.createCalls, 1);
    },
  );
}
