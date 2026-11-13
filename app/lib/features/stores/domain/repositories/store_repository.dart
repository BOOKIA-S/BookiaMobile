import 'package:bookia_mobile/features/stores/domain/entities/store.dart';

abstract interface class StoreRepository {
  /// Store with its catalog. Throws a Failure on error (404 if unknown).
  Future<StoreDetail> getStore(String id);

  /// All stores. With [lat] and [lng] they come nearest first, each with its
  /// distance; without them they come ordered by name.
  Future<List<Store>> getStores({double? lat, double? lng});
}
