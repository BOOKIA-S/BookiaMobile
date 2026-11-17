import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:geolocator/geolocator.dart';

/// [LocationService] backed by `geolocator`.
class GeolocatorLocationService implements LocationService {
  GeolocatorLocationService({
    GeolocatorPlatform? platform,
    this.timeout = const Duration(seconds: 8),
  }) : _platform = platform ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _platform;

  /// Longest wait for a GPS fix before falling back to the last known one.
  final Duration timeout;

  static LocationAccess _toAccess(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => LocationAccess.denied,
      };

  @override
  Future<LocationAccess> checkAccess() async =>
      _toAccess(await _platform.checkPermission());

  @override
  Future<LocationAccess> requestAccess() async {
    final current = await checkAccess();
    if (current != LocationAccess.denied) return current;
    return _toAccess(await _platform.requestPermission());
  }

  @override
  Future<GeoPoint?> currentPosition() async {
    try {
      if (await checkAccess() != LocationAccess.granted) return null;
      if (!await _platform.isLocationServiceEnabled()) return null;
      final position = await _platform
          .getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          )
          .timeout(timeout, onTimeout: () => _lastKnown());
      return (lat: position.latitude, lng: position.longitude);
    } on Exception {
      return null;
    }
  }

  Future<Position> _lastKnown() async {
    final last = await _platform.getLastKnownPosition();
    if (last == null) throw const LocationServiceDisabledException();
    return last;
  }

  @override
  Future<bool> openSettings() => _platform.openAppSettings();
}
