import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/location/location_providers.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/stores/data/repositories/store_repository_impl.dart';
import 'package:bookia_mobile/features/stores/domain/repositories/store_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => StoreRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Position of the user from LocationService, or null when it is unknown
/// (screen 02 declined or no GPS): then the store list comes ordered by name
/// instead of by distance.
final userPositionProvider = Provider<GeoPoint?>(
  (ref) => ref.watch(currentPositionProvider),
);
