import 'package:bookia_mobile/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the "screen 02 already shown" flag on the phone. If the storage
/// fails, the screen is simply shown again on the next start.
class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl({this.storage = const FlutterSecureStorage()});

  static const key = 'onboarding_location_asked';
  final FlutterSecureStorage storage;

  @override
  Future<bool> wasLocationAsked() async {
    try {
      return await storage.read(key: key) == 'true';
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> markLocationAsked() async {
    try {
      await storage.write(key: key, value: 'true');
    } on Exception {
      // Not critical: worst case the screen appears once more.
    }
  }
}
