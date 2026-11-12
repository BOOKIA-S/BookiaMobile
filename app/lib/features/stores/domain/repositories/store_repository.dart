import 'package:bookia_mobile/features/stores/domain/entities/store.dart';

abstract interface class StoreRepository {
  /// Store with its catalog. Throws a Failure on error (404 if unknown).
  Future<StoreDetail> getStore(String id);
}
