/// Remembers whether screen 02 was already shown on this phone.
abstract interface class OnboardingRepository {
  Future<bool> wasLocationAsked();

  Future<void> markLocationAsked();
}
