import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Google Map with one pin per store and the position of the user.
/// Every store in [stores] must have coordinates.
class StoresMapView extends StatelessWidget {
  const StoresMapView({
    required this.stores,
    required this.selectedId,
    required this.onSelect,
    this.user,
    super.key,
  });

  final List<Store> stores;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final GeoPoint? user;

  /// Huauchinango, when there are no stores to center on.
  static const _fallbackCenter = LatLng(20.1763, -98.0508);

  LatLng get _center {
    if (stores.isEmpty) return _fallbackCenter;
    final lat = stores.fold(0.0, (sum, s) => sum + s.lat!);
    final lng = stores.fold(0.0, (sum, s) => sum + s.lng!);
    return LatLng(lat / stores.length, lng / stores.length);
  }

  @override
  Widget build(BuildContext context) => GoogleMap(
    initialCameraPosition: CameraPosition(target: _center, zoom: 14),
    markers: {
      for (final s in stores)
        Marker(
          markerId: MarkerId(s.id),
          position: LatLng(s.lat!, s.lng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            s.id == selectedId
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueRed,
          ),
          onTap: () => onSelect(s.id),
        ),
    },
    myLocationEnabled: user != null,
    myLocationButtonEnabled: user != null,
    zoomControlsEnabled: false,
    mapToolbarEnabled: false,
    onTap: (_) => onSelect(null),
  );
}
