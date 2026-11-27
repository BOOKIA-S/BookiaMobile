import 'package:bookia_mobile/features/notifications/domain/repositories/device_repository.dart';

/// Links the phone's FCM token to the signed-in account (screen 13).
class RegisterDeviceToken {
  const RegisterDeviceToken(this._repository);

  final DeviceRepository _repository;

  /// Blank tokens are ignored; platforms other than `ios` are sent as
  /// `android`, the only two values the API accepts.
  Future<void> call({required String token, required String platform}) async {
    final clean = token.trim();
    if (clean.isEmpty) return;
    await _repository.register(
      token: clean,
      platform: platform == 'ios' ? 'ios' : 'android',
    );
  }
}
