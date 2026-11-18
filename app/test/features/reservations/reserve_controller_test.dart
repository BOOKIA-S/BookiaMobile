import 'dart:async';

import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_controller.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_test_helpers.dart';
import 'reserve_controller_harness.dart';

void main() {
  test('build loads the offer and starts prepared', () async {
    final container = reserveContainer();
    final state = await container.read(
      reserveControllerProvider(reserveKey).future,
    );

    expect(state.offer.bookTitle, 'Aura');
    expect(state.offer.offerId, 'o1');
    expect(state.quantity, 1);
    expect(state.maxQuantity, 5);
    expect(state.total, 129);
    expect(state.status, isA<ReservePrepared>());
    expect(state.created, isNull);
    expect(state.failure, isNull);
  });

  test('build fails safely when the offer no longer exists', () async {
    final container = reserveContainer(
      offers: FakeReservableOfferSource(missing: true),
    );
    await expectLater(
      container.read(reserveControllerProvider(reserveKey).future),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('quantity stays between 1 and min(5, stock)', () async {
    final container = reserveContainer(
      offers: FakeReservableOfferSource(offer: testOffer(stock: 2)),
    );
    await container.read(reserveControllerProvider(reserveKey).future);
    final controller = container.read(
      reserveControllerProvider(reserveKey).notifier,
    );

    controller.decrement();
    expect(stateOf(container).quantity, 1);
    controller.increment();
    controller.increment();
    expect(stateOf(container).quantity, 2);
    expect(stateOf(container).maxQuantity, 2);
  });

  test('a guest cannot reserve and no request is sent', () async {
    final reservations = FakeReservationRepository();
    final container = reserveContainer(reservations: reservations);
    await container.read(reserveControllerProvider(reserveKey).future);

    await container
        .read(reserveControllerProvider(reserveKey).notifier)
        .submit();

    expect(stateOf(container).failure, isA<UnauthorizedFailure>());
    expect(stateOf(container).status, isA<ReserveFailed>());
    expect(reservations.createCalls, 0);
  });

  test('store staff cannot create reader reservations', () async {
    final reservations = FakeReservationRepository();
    final container = reserveContainer(reservations: reservations);
    signIn(container, role: 'store_owner');
    await container.read(reserveControllerProvider(reserveKey).future);

    await container
        .read(reserveControllerProvider(reserveKey).notifier)
        .submit();

    expect(stateOf(container).failure, isA<ForbiddenFailure>());
    expect(reservations.createCalls, 0);
  });

  test('a reader creates one reservation with the chosen quantity', () async {
    final reservations = FakeReservationRepository()
      ..onCreate = (_, quantity) async =>
          testReservation(price: 99, quantity: quantity);
    final container = reserveContainer(reservations: reservations);
    signIn(container);
    await container.read(reserveControllerProvider(reserveKey).future);
    final controller = container.read(
      reserveControllerProvider(reserveKey).notifier,
    );
    controller.increment();

    await controller.submit();

    expect(reservations.lastOfferId, 'o1');
    expect(reservations.lastQuantity, 2);
    expect(stateOf(container).status, isA<ReserveSucceeded>());
    expect(stateOf(container).created!.total, 198);
    expect(stateOf(container).failure, isNull);
  });

  test('double taps send a single request', () async {
    final pending = Completer<Reservation>();
    final reservations = FakeReservationRepository()
      ..onCreate = (_, _) => pending.future;
    final container = reserveContainer(reservations: reservations);
    signIn(container);
    await container.read(reserveControllerProvider(reserveKey).future);
    final controller = container.read(
      reserveControllerProvider(reserveKey).notifier,
    );

    final first = controller.submit();
    final second = controller.submit();
    expect(reservations.createCalls, 1);
    expect(stateOf(container).isSending, isTrue);

    pending.complete(testReservation());
    await first;
    await second;
    expect(reservations.createCalls, 1);
    expect(stateOf(container).status, isA<ReserveSucceeded>());
  });

  test('a timeout leaves an uncertain attempt locked', () async {
    final container = reserveContainer();
    await makeUncertain(container);

    final state = stateOf(container);
    expect(state.status, isA<ReserveUncertain>());
    expect(state.created, isNull);
    expect(state.canVerify, isTrue);
    expect(state.isLocked, isTrue);
    expect(state.attempt!.quantity, 2);
  });

  test('a server failure after sending is ambiguous too', () async {
    final container = reserveContainer();
    await makeUncertain(container, failure: const ServerFailure());

    expect(stateOf(container).status, isA<ReserveUncertain>());
    expect(stateOf(container).isLocked, isTrue);
  });

  test('a definitive rejection unlocks the form', () async {
    final reservations = FakeReservationRepository();
    reservations.onCreate = (_, _) async => throw const ConflictFailure('x');
    final container = reserveContainer(reservations: reservations);
    signIn(container);
    await container.read(reserveControllerProvider(reserveKey).future);
    final controller = container.read(
      reserveControllerProvider(reserveKey).notifier,
    );

    await controller.submit();

    expect(stateOf(container).status, isA<ReserveFailed>());
    expect(stateOf(container).isLocked, isFalse);
    expect(stateOf(container).canVerify, isFalse);
    await controller.submit();
    expect(reservations.createCalls, 2);
  });

  test('a session change discards the attempt and its result', () async {
    final reservations = FakeReservationRepository();
    final container = reserveContainer(reservations: reservations);
    final subscription = container.listen(
      reserveControllerProvider(reserveKey),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await makeUncertain(container);
    reservations.onList = () async => [
      testReservation(quantity: 2, createdAt: DateTime.now().toUtc()),
    ];

    container
        .read(currentSessionProvider.notifier)
        .set(const SignedInSession(name: 'Ana', role: 'reader'));
    await pumpEventQueue();

    expect(stateOf(container).status, isA<ReservePrepared>());
    expect(stateOf(container).isLocked, isFalse);
    await container
        .read(reserveControllerProvider(reserveKey).notifier)
        .verify();
    expect(reservations.listCalls, 0);
  });

  test(
    'abandon unlocks only after a local discard and keeps a notice',
    () async {
      final reservations = FakeReservationRepository();
      final container = reserveContainer(reservations: reservations);
      await makeUncertain(container);
      final controller = container.read(
        reserveControllerProvider(reserveKey).notifier,
      );

      controller.abandon();

      expect(stateOf(container).status, isA<ReservePrepared>());
      expect(stateOf(container).notice, contains('no se canceló'));
      expect(stateOf(container).isLocked, isFalse);
      await controller.submit();
      expect(reservations.createCalls, 2);
    },
  );

  test('the succeeded state survives a provider read', () async {
    final reservations = FakeReservationRepository();
    final container = reserveContainer(reservations: reservations);
    signIn(container);
    await container.read(reserveControllerProvider(reserveKey).future);
    await container
        .read(reserveControllerProvider(reserveKey).notifier)
        .submit();

    final again = container.read(reserveControllerProvider(reserveKey)).value!;
    expect(again.status, isA<ReserveSucceeded>());
    expect(reservations.createCalls, 1);
  });
}
