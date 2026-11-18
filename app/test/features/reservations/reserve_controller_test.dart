import 'dart:async';

import 'package:bookia_mobile/app/di.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_controller.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_state.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_test_helpers.dart';

const _key = (bookId: 'b1', offerId: 'o1');

ProviderContainer _container({
  FakeReservableOfferSource? offers,
  FakeReservationRepository? reservations,
}) {
  final container = ProviderContainer(
    overrides: [
      reservableOfferSourceProvider.overrideWithValue(
        offers ?? FakeReservableOfferSource(),
      ),
      reservationRepositoryProvider.overrideWithValue(
        reservations ?? FakeReservationRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void _signIn(ProviderContainer container, {String role = 'reader'}) => container
    .read(currentSessionProvider.notifier)
    .set(SignedInSession(name: 'Ana', role: role));

ReserveState _state(ProviderContainer container) =>
    container.read(reserveControllerProvider(_key)).value!;

Future<void> _uncertain(
  ProviderContainer container, {
  Failure failure = const NetworkFailure(),
}) async {
  final reservations = container.read(
    reservationRepositoryProvider,
  ) as FakeReservationRepository;
  reservations.onCreate = (_, _) async => throw failure;
  _signIn(container);
  await container.read(reserveControllerProvider(_key).future);
  final controller = container.read(reserveControllerProvider(_key).notifier);
  controller.increment();
  await controller.submit();
}

void main() {
  test('build loads the offer and starts prepared', () async {
    final container = _container();
    final state = await container.read(reserveControllerProvider(_key).future);

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
    final container = _container(
      offers: FakeReservableOfferSource(missing: true),
    );
    await expectLater(
      container.read(reserveControllerProvider(_key).future),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('quantity stays between 1 and min(5, stock)', () async {
    final container = _container(
      offers: FakeReservableOfferSource(offer: testOffer(stock: 2)),
    );
    await container.read(reserveControllerProvider(_key).future);
    final controller = container.read(reserveControllerProvider(_key).notifier);

    controller.decrement();
    expect(_state(container).quantity, 1);
    controller.increment();
    controller.increment();
    expect(_state(container).quantity, 2);
    expect(_state(container).maxQuantity, 2);
  });

  test('a guest cannot reserve and no request is sent', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    await container.read(reserveControllerProvider(_key).future);

    await container.read(reserveControllerProvider(_key).notifier).submit();

    expect(_state(container).failure, isA<UnauthorizedFailure>());
    expect(_state(container).status, isA<ReserveFailed>());
    expect(reservations.createCalls, 0);
  });

  test('store staff cannot create reader reservations', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    _signIn(container, role: 'store_owner');
    await container.read(reserveControllerProvider(_key).future);

    await container.read(reserveControllerProvider(_key).notifier).submit();

    expect(_state(container).failure, isA<ForbiddenFailure>());
    expect(reservations.createCalls, 0);
  });

  test('a reader creates one reservation with the chosen quantity', () async {
    final reservations = FakeReservationRepository()
      ..onCreate = (_, quantity) async =>
          testReservation(price: 99, quantity: quantity);
    final container = _container(reservations: reservations);
    _signIn(container);
    await container.read(reserveControllerProvider(_key).future);
    final controller = container.read(reserveControllerProvider(_key).notifier);
    controller.increment();

    await controller.submit();

    expect(reservations.lastOfferId, 'o1');
    expect(reservations.lastQuantity, 2);
    expect(_state(container).status, isA<ReserveSucceeded>());
    expect(_state(container).created!.total, 198);
    expect(_state(container).failure, isNull);
  });

  test('double taps send a single request', () async {
    final pending = Completer<Reservation>();
    final reservations = FakeReservationRepository()
      ..onCreate = (_, _) => pending.future;
    final container = _container(reservations: reservations);
    _signIn(container);
    await container.read(reserveControllerProvider(_key).future);
    final controller = container.read(reserveControllerProvider(_key).notifier);

    final first = controller.submit();
    final second = controller.submit();
    expect(reservations.createCalls, 1);
    expect(_state(container).isSending, isTrue);

    pending.complete(testReservation());
    await first;
    await second;
    expect(reservations.createCalls, 1);
    expect(_state(container).status, isA<ReserveSucceeded>());
  });

  test('a timeout leaves an uncertain attempt locked', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    await _uncertain(container);

    final state = _state(container);
    expect(state.status, isA<ReserveUncertain>());
    expect(state.created, isNull);
    expect(state.canVerify, isTrue);
    expect(state.isLocked, isTrue);
    expect(state.attempt!.quantity, 2);
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
      final container = _container(reservations: reservations);
      _signIn(container);
      await container.read(reserveControllerProvider(_key).future);
      final controller = container.read(
        reserveControllerProvider(_key).notifier,
      );
      await controller.submit();
      reservations.onList = () async => serverCreated;

      await controller.verify();

      final state = _state(container);
      expect(state.status, isA<ReserveCandidates>());
      expect(state.created, isNull);
      expect(state.candidates.single.id, 'lost');
      await controller.submit();
      expect(reservations.createCalls, 1);
    },
  );

  test('a server failure after sending is ambiguous too', () async {
    final container = _container();
    await _uncertain(container, failure: const ServerFailure());

    expect(_state(container).status, isA<ReserveUncertain>());
    expect(_state(container).isLocked, isTrue);
  });

  test('a definitive rejection unlocks the form', () async {
    final reservations = FakeReservationRepository();
    reservations.onCreate = (_, _) async => throw const ConflictFailure('x');
    final container = _container(reservations: reservations);
    _signIn(container);
    await container.read(reserveControllerProvider(_key).future);
    final controller = container.read(reserveControllerProvider(_key).notifier);

    await controller.submit();

    expect(_state(container).status, isA<ReserveFailed>());
    expect(_state(container).isLocked, isFalse);
    expect(_state(container).canVerify, isFalse);
    await controller.submit();
    expect(reservations.createCalls, 2);
  });

  test('verify shows a recent match only as a candidate', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    await _uncertain(container);
    reservations.onList = () async => [
      testReservation(id: 'r9', quantity: 2, createdAt: DateTime.now().toUtc()),
    ];

    await container.read(reserveControllerProvider(_key).notifier).verify();

    final state = _state(container);
    expect(state.status, isA<ReserveCandidates>());
    expect(state.created, isNull);
    expect(state.candidates, hasLength(1));
    expect(state.candidates.single.id, 'r9');
    expect(reservations.createCalls, 1);
  });

  test('an older reservation of the same offer is not a candidate', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    await _uncertain(container);
    reservations.onList = () async => [
      testReservation(
        id: 'old',
        quantity: 2,
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
      ),
    ];

    await container.read(reserveControllerProvider(_key).notifier).verify();

    final state = _state(container);
    expect(state.status, isA<ReserveUncertain>());
    expect(state.created, isNull);
    expect(state.candidates, isEmpty);
    expect(state.canVerify, isTrue);
    expect(state.isLocked, isTrue);
    await container.read(reserveControllerProvider(_key).notifier).submit();
    expect(reservations.createCalls, 1);
  });

  test('a reservation with another quantity is not a candidate', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    await _uncertain(container);
    reservations.onList = () async => [
      testReservation(
        id: 'other-quantity',
        quantity: 1,
        createdAt: DateTime.now().toUtc(),
      ),
    ];

    await container.read(reserveControllerProvider(_key).notifier).verify();

    expect(_state(container).candidates, isEmpty);
    expect(_state(container).status, isA<ReserveUncertain>());
  });

  test('multiple candidates are all shown without choosing one', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    await _uncertain(container);
    reservations.onList = () async => [
      testReservation(id: 'r1', quantity: 2, createdAt: DateTime.now().toUtc()),
      testReservation(id: 'r2', quantity: 2, createdAt: DateTime.now().toUtc()),
    ];

    await container.read(reserveControllerProvider(_key).notifier).verify();

    expect(_state(container).candidates, hasLength(2));
    expect(_state(container).created, isNull);
  });

  test('an empty or failed list does not prove the POST failed', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    await _uncertain(container);
    reservations.onList = () async => <Reservation>[];

    await container.read(reserveControllerProvider(_key).notifier).verify();

    expect(_state(container).status, isA<ReserveUncertain>());
    expect(_state(container).failure, isA<ConflictFailure>());
    expect(_state(container).canVerify, isTrue);
    expect(_state(container).created, isNull);

    reservations.onList = () async => throw const ServerFailure();
    await container.read(reserveControllerProvider(_key).notifier).verify();
    expect(_state(container).failure, isA<ServerFailure>());
    expect(_state(container).isLocked, isTrue);
    expect(reservations.createCalls, 1);
  });

  test('changing quantity does not erase the uncertain attempt', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    await _uncertain(container);
    final controller = container.read(reserveControllerProvider(_key).notifier);

    controller.decrement();
    expect(_state(container).quantity, 1);
    expect(_state(container).attempt!.quantity, 2);
    await controller.submit();
    expect(reservations.createCalls, 1);
  });

  test('a session change discards the attempt and its result', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    final subscription = container.listen(
      reserveControllerProvider(_key),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await _uncertain(container);
    reservations.onList = () async => [
      testReservation(quantity: 2, createdAt: DateTime.now().toUtc()),
    ];

    container
        .read(currentSessionProvider.notifier)
        .set(const SignedInSession(name: 'Ana', role: 'reader'));
    await pumpEventQueue();

    expect(_state(container).status, isA<ReservePrepared>());
    expect(_state(container).isLocked, isFalse);
    await container.read(reserveControllerProvider(_key).notifier).verify();
    expect(reservations.listCalls, 0);
  });

  test(
    'abandon unlocks only after a local discard and keeps a notice',
    () async {
      final reservations = FakeReservationRepository();
      final container = _container(reservations: reservations);
      await _uncertain(container);
      final controller = container.read(
        reserveControllerProvider(_key).notifier,
      );

      controller.abandon();

      expect(_state(container).status, isA<ReservePrepared>());
      expect(_state(container).notice, contains('no se canceló'));
      expect(_state(container).isLocked, isFalse);
      await controller.submit();
      expect(reservations.createCalls, 2);
    },
  );

  test('the succeeded state survives a provider read', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    _signIn(container);
    await container.read(reserveControllerProvider(_key).future);
    await container.read(reserveControllerProvider(_key).notifier).submit();

    final again = container.read(reserveControllerProvider(_key)).value!;
    expect(again.status, isA<ReserveSucceeded>());
    expect(reservations.createCalls, 1);
  });
}
