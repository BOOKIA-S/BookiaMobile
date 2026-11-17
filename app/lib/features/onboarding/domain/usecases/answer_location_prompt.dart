import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Answer of screen 02: "Permitir ubicación" or "Ahora no". Either way the
/// screen is not shown again.
class AnswerLocationPrompt {
  const AnswerLocationPrompt(this._location, this._repository);

  final LocationService _location;
  final OnboardingRepository _repository;

  /// Shows the system dialog and returns the resulting access.
  Future<LocationAccess> allow() async {
    await _repository.markLocationAsked();
    return _location.requestAccess();
  }

  Future<void> skip() => _repository.markLocationAsked();
}
