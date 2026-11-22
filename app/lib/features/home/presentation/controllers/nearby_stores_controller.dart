import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) of "Librerías cerca de ti" (I2-11): the nearest
/// stores from `/stores/near`, or null while the position is unknown.
class NearbyStoresController extends AsyncNotifier<List<Store>?> {
  static const size = 3;

  @override
  Future<List<Store>?> build() async {
    final position = ref.watch(userPositionProvider);
    if (position == null) return null;
    final stores = await ref
        .read(storeRepositoryProvider)
        .getStores(lat: position.lat, lng: position.lng);
    return stores.take(size).toList();
  }
}

final nearbyStoresProvider =
    AsyncNotifierProvider.autoDispose<NearbyStoresController, List<Store>?>(
      NearbyStoresController.new,
    );
