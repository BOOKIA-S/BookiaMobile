import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/presentation/controllers/stores_list_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) of screen 08: id of the store whose quick card is
/// open, or null when none is.
class SelectedStore extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedStoreIdProvider =
    NotifierProvider.autoDispose<SelectedStore, String?>(SelectedStore.new);

/// Stores that can be drawn on the map: the ones with coordinates.
final mapStoresProvider = Provider.autoDispose<AsyncValue<List<Store>>>(
  (ref) => ref
      .watch(storesListProvider)
      .whenData(
        (stores) => [
          for (final s in stores)
            if (s.lat != null && s.lng != null) s,
        ],
      ),
);

/// Distance in km from [user] to [store]: the one the API gave, otherwise
/// computed on the phone. Null when it cannot be known.
double? distanceToStore(Store store, GeoPoint? user) {
  final known = store.distanceKm;
  if (known != null) return known;
  final lat = store.lat;
  final lng = store.lng;
  if (user == null || lat == null || lng == null) return null;
  return distanceKm(user, (lat: lat, lng: lng));
}
