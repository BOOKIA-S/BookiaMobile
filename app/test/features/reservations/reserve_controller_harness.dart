import 'package:bookia_mobile/app/di.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_controller.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_state.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_test_helpers.dart';

const reserveKey = (bookId: 'b1', offerId: 'o1');

ProviderContainer reserveContainer({
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

void signIn(ProviderContainer container, {String role = 'reader'}) => container
    .read(currentSessionProvider.notifier)
    .set(SignedInSession(name: 'Ana', role: role));

ReserveState stateOf(ProviderContainer container) =>
    container.read(reserveControllerProvider(reserveKey)).value!;

/// Starts a reader attempt of two copies that ends in an ambiguous failure.
Future<void> makeUncertain(
  ProviderContainer container, {
  Failure failure = const NetworkFailure(),
}) async {
  final reservations = container.read(
    reservationRepositoryProvider,
  ) as FakeReservationRepository;
  reservations.onCreate = (_, _) async => throw failure;
  signIn(container);
  await container.read(reserveControllerProvider(reserveKey).future);
  final controller = container.read(
    reserveControllerProvider(reserveKey).notifier,
  );
  controller.increment();
  await controller.submit();
}
