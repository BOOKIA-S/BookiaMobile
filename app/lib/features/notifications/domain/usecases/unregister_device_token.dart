import 'package:bookia_mobile/features/notifications/domain/repositories/device_repository.dart';

/// Stops the pushes of an account on this phone when the user signs out.
class UnregisterDeviceToken {
  const UnregisterDeviceToken(this._repository);

  final DeviceRepository _repository;

  Future<void> call(String token) async {
    if (token.trim().isEmpty) return;
    await _repository.unregister(token.trim());
  }
}
