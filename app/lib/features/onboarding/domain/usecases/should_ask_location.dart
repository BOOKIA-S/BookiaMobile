import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Screen 02 is shown once, and only while the permission is not granted.
class ShouldAskLocation {
  const ShouldAskLocation(this._location, this._repository);

  final LocationService _location;
  final OnboardingRepository _repository;

  Future<bool> call() async {
    if (await _repository.wasLocationAsked()) return false;
    return await _location.checkAccess() != LocationAccess.granted;
  }
}
