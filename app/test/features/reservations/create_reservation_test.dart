import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/domain/usecases/create_reservation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_test_helpers.dart';

void main() {
  test('rejects an empty offer and quantities outside 1..5', () async {
    final repository = FakeReservationRepository();
    final create = CreateReservation(repository);

    for (final (offerId, quantity) in [
      ('', 1),
      ('   ', 1),
      ('o1', 0),
      ('o1', -1),
      ('o1', 6),
      ('o1', 10),
    ]) {
      expect(
        () => create(offerId: offerId, quantity: quantity),
        throwsA(isA<ValidationFailure>()),
      );
    }
    expect(repository.createCalls, 0);
  });

  test('delegates a valid request to the repository', () async {
    final repository = FakeReservationRepository();
    final reservation = await CreateReservation(repository)(
      offerId: 'o1',
      quantity: 5,
    );

    expect(repository.createCalls, 1);
    expect(repository.lastOfferId, 'o1');
    expect(repository.lastQuantity, 5);
    expect(reservation.quantity, 5);
  });
}
