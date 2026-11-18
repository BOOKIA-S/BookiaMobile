import 'dart:async';

import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/books/presentation/providers.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_controller.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_test_helpers.dart';

const _key = (bookId: 'b1', offerId: 'o1');

ProviderContainer _container({
  FakeBookRepository? books,
  FakeReservationRepository? reservations,
}) {
  final container = ProviderContainer(
    overrides: [
      bookRepositoryProvider.overrideWithValue(books ?? FakeBookRepository()),
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

void main() {
  test('build loads the offer and starts at one copy', () async {
    final container = _container();
    final state = await container.read(reserveControllerProvider(_key).future);

    expect(state.book.title, 'Aura');
    expect(state.offer.id, 'o1');
    expect(state.quantity, 1);
    expect(state.maxQuantity, 5);
    expect(state.total, 129);
    expect(state.created, isNull);
    expect(state.failure, isNull);
  });

  test('build fails safely when the offer no longer exists', () async {
    const key = (bookId: 'b1', offerId: 'gone');
    final container = _container();
    await expectLater(
      container.read(reserveControllerProvider(key).future),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('quantity stays between 1 and min(5, stock)', () async {
    final container = _container(books: FakeBookRepository(testBook(stock: 2)));
    await container.read(reserveControllerProvider(_key).future);
    final controller = container.read(reserveControllerProvider(_key).notifier);

    controller.decrement();
    expect(container.read(reserveControllerProvider(_key)).value!.quantity, 1);
    controller.increment();
    controller.increment();
    expect(container.read(reserveControllerProvider(_key)).value!.quantity, 2);
    expect(
      container.read(reserveControllerProvider(_key)).value!.maxQuantity,
      2,
    );
  });

  test('a guest cannot reserve and no request is sent', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    await container.read(reserveControllerProvider(_key).future);

    await container.read(reserveControllerProvider(_key).notifier).submit();

    final state = container.read(reserveControllerProvider(_key)).value!;
    expect(state.failure, isA<UnauthorizedFailure>());
    expect(reservations.createCalls, 0);
  });

  test('store staff cannot create reader reservations', () async {
    final reservations = FakeReservationRepository();
    final container = _container(reservations: reservations);
    _signIn(container, role: 'store_owner');
    await container.read(reserveControllerProvider(_key).future);

    await container.read(reserveControllerProvider(_key).notifier).submit();

    final state = container.read(reserveControllerProvider(_key)).value!;
    expect(
      state.failure,
      isA<ForbiddenFailure>().having(
        (f) => f.message,
        'message',
        contains('lector'),
      ),
    );
    expect(reservations.createCalls, 0);
  });

  test('a reader creates one reservation with the chosen quantity', () async {
    final reservations = FakeReservationRepository()
      ..onCreate = (offerId, quantity) async =>
          testReservation(price: 99, quantity: quantity);
    final container = _container(reservations: reservations);
    _signIn(container);
    await container.read(reserveControllerProvider(_key).future);
    final controller = container.read(reserveControllerProvider(_key).notifier);
    controller.increment();

    await controller.submit();

    final state = container.read(reserveControllerProvider(_key)).value!;
    expect(reservations.lastOfferId, 'o1');
    expect(reservations.lastQuantity, 2);
    expect(state.created!.total, 198);
    expect(state.failure, isNull);
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
    expect(
      container.read(reserveControllerProvider(_key)).value!.isSubmitting,
      isTrue,
    );

    pending.complete(testReservation());
    await first;
    await second;
    expect(reservations.createCalls, 1);
  });

  test('a timeout offers verification and never resends the request', () async {
    final reservations = FakeReservationRepository()
      ..onCreate = (_, _) async => throw const NetworkFailure();
    final container = _container(reservations: reservations);
    _signIn(container);
    await container.read(reserveControllerProvider(_key).future);
    final controller = container.read(reserveControllerProvider(_key).notifier);

    await controller.submit();
    expect(
      container.read(reserveControllerProvider(_key)).value!.canVerify,
      isTrue,
    );
    expect(reservations.createCalls, 1);

    reservations.onList = () async => [testReservation(id: 'r9')];
    await controller.verify();

    final state = container.read(reserveControllerProvider(_key)).value!;
    expect(state.created!.id, 'r9');
    expect(reservations.createCalls, 1);
    expect(reservations.listCalls, 1);
  });

  test('verification reports when nothing was created', () async {
    final reservations = FakeReservationRepository();
    reservations.onCreate = (_, _) async => throw const NetworkFailure();
    reservations.onList = () async => <Reservation>[];
    final container = _container(reservations: reservations);
    _signIn(container);
    await container.read(reserveControllerProvider(_key).future);
    final controller = container.read(reserveControllerProvider(_key).notifier);

    await controller.submit();
    await controller.verify();

    final state = container.read(reserveControllerProvider(_key)).value!;
    expect(state.failure, isA<ConflictFailure>());
    expect(state.created, isNull);
    expect(reservations.createCalls, 1);
  });

  test(
    'a failed request keeps the button available for a new attempt',
    () async {
      final reservations = FakeReservationRepository()
        ..onCreate = (_, _) async => throw const ConflictFailure('agotado');
      final container = _container(reservations: reservations);
      _signIn(container);
      await container.read(reserveControllerProvider(_key).future);
      final controller = container.read(
        reserveControllerProvider(_key).notifier,
      );

      await controller.submit();

      final state = container.read(reserveControllerProvider(_key)).value!;
      expect(state.isSubmitting, isFalse);
      expect(state.failure, isA<ConflictFailure>());
      expect(state.canVerify, isFalse);
    },
  );
}
