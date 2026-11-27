import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/notifications/data/datasources/device_remote_data_source.dart';
import 'package:bookia_mobile/features/notifications/data/repositories/device_repository_impl.dart';
import 'package:bookia_mobile/features/notifications/domain/repositories/device_repository.dart';
import 'package:bookia_mobile/features/notifications/domain/usecases/register_device_token.dart';
import 'package:bookia_mobile/features/notifications/domain/usecases/unregister_device_token.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider/DI (PAT-03): the controller depends on use cases, not on data/.
final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepositoryImpl(
    DeviceRemoteDataSource(ref.watch(apiClientProvider)),
  ),
);

final registerDeviceTokenProvider = Provider<RegisterDeviceToken>(
  (ref) => RegisterDeviceToken(ref.watch(deviceRepositoryProvider)),
);

final unregisterDeviceTokenProvider = Provider<UnregisterDeviceToken>(
  (ref) => UnregisterDeviceToken(ref.watch(deviceRepositoryProvider)),
);
