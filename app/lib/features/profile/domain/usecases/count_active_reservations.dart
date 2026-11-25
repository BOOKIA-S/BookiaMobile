import 'package:bookia_mobile/features/profile/domain/repositories/profile_repository.dart';

/// Active reservations for the profile counter.
class CountActiveReservations {
  const CountActiveReservations(this._repository);

  final ProfileRepository _repository;

  Future<int> call() => _repository.activeReservationCount();
}
