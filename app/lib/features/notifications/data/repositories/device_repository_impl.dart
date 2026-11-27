import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/notifications/data/datasources/device_remote_data_source.dart';
import 'package:bookia_mobile/features/notifications/domain/repositories/device_repository.dart';

/// Repository (PAT-01): the API only answers 400 here when the token or the
/// platform is invalid, so that message is translated to Spanish.
class DeviceRepositoryImpl implements DeviceRepository {
  const DeviceRepositoryImpl(this._remote);

  final DeviceRemoteDataSource _remote;

  @override
  Future<void> register({
    required String token,
    required String platform,
  }) async {
    try {
      await _remote.register(token: token, platform: platform);
    } on ValidationFailure {
      throw const ValidationFailure(
        'No pudimos activar las notificaciones en este teléfono.',
      );
    }
  }

  @override
  Future<void> unregister(String token) => _remote.unregister(token);
}
