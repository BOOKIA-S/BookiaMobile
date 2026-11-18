import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:bookia_mobile/features/reservations/data/repositories/reservation_repository_impl.dart';
import 'package:bookia_mobile/features/reservations/domain/repositories/reservation_repository.dart';
import 'package:bookia_mobile/features/reservations/domain/usecases/create_reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/usecases/find_my_reservation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider/DI (PAT-03): screens depend on the interfaces, not on data/.
final reservationRepositoryProvider = Provider<ReservationRepository>(
  (ref) => ReservationRepositoryImpl(
    ReservationRemoteDataSource(ref.watch(apiClientProvider)),
  ),
);

final createReservationProvider = Provider<CreateReservation>(
  (ref) => CreateReservation(ref.watch(reservationRepositoryProvider)),
);

final findMyReservationProvider = Provider<FindMyReservation>(
  (ref) => FindMyReservation(ref.watch(reservationRepositoryProvider)),
);
