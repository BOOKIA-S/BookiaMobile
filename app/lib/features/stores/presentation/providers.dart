import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/stores/data/repositories/store_repository_impl.dart';
import 'package:bookia_mobile/features/stores/domain/repositories/store_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => StoreRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Position of the user, or null when it is unknown.
///
/// Placeholder until LocationService (I1-07) exists: while it is null the
/// store list comes ordered by name instead of by distance.
final userPositionProvider = Provider<({double lat, double lng})?>(
  (ref) => null,
);
