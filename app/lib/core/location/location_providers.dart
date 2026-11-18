import 'package:bookia_mobile/core/location/geolocator_location_service.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton (PAT-04) LocationService for the whole app.
final locationServiceProvider = Provider<LocationService>(
  (_) => GeolocatorLocationService(),
);

/// Last known position of the user (Observer, PAT-06). Null until the
/// permission is granted and the GPS answers.
class CurrentPosition extends Notifier<GeoPoint?> {
  @override
  GeoPoint? build() => null;

  /// Asks the service for a fresh position; keeps the old one if it fails.
  Future<GeoPoint?> refresh() async {
    final position = await ref.read(locationServiceProvider).currentPosition();
    if (position != null && ref.mounted) state = position;
    return position;
  }
}

final currentPositionProvider = NotifierProvider<CurrentPosition, GeoPoint?>(
  CurrentPosition.new,
);
