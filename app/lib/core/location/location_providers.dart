import 'package:bookia_mobile/core/location/geolocator_location_service.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/core/preferences/preferences_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton (PAT-04) LocationService for the whole app.
final locationServiceProvider = Provider<LocationService>(
  (_) => GeolocatorLocationService(),
);

/// Last known position of the user (Observer, PAT-06). Null until the
/// permission is granted and the GPS answers.
class CurrentPosition extends Notifier<GeoPoint?> {
  @override
  GeoPoint? build() {
    ref.listen(appPreferencesProvider, (previous, next) {
      final enabled =
          next.value?.useLocation ?? previous?.value?.useLocation ?? true;
      if (!enabled && ref.mounted) state = null;
    });
    return null;
  }

  /// Asks the service for a fresh position; keeps the old one if it fails.
  /// When the "Usar mi ubicación" preference is off, it forgets the previous
  /// position and never asks the platform, so no coordinates are sent.
  Future<GeoPoint?> refresh() async {
    final enabled = (await ref.read(appPreferencesProvider.future)).useLocation;
    if (!enabled) {
      if (ref.mounted) state = null;
      return null;
    }
    final position = await ref.read(locationServiceProvider).currentPosition();
    if (position != null && ref.mounted) state = position;
    return position;
  }

  void clear() {
    if (ref.mounted) state = null;
  }
}

final currentPositionProvider = NotifierProvider<CurrentPosition, GeoPoint?>(
  CurrentPosition.new,
);
