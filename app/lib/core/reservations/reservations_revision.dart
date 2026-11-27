import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Grows whenever the reader creates or cancels a reservation, so the
/// profile activity counter refreshes without importing the reservations
/// feature.
class ReservationsRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final reservationsRevisionProvider =
    NotifierProvider<ReservationsRevision, int>(ReservationsRevision.new);
