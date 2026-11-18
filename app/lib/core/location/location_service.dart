import 'dart:math' as math;

/// A point on the map, in degrees.
typedef GeoPoint = ({double lat, double lng});

/// What the app may do with the location of the user.
enum LocationAccess {
  /// Allowed (while in use or always).
  granted,

  /// Not allowed yet; the system dialog can still be shown.
  denied,

  /// Blocked; only the app settings can change it.
  deniedForever,
}

/// Facade (PAT-11) over the platform location APIs: permission, position
/// and distance. The position is only used on the phone to sort stores by
/// distance and draw routes; it is never sent or stored by BOOKIA (SEG-04).
abstract interface class LocationService {
  /// Current permission, without showing any dialog.
  Future<LocationAccess> checkAccess();

  /// Shows the system dialog when it can still be shown.
  Future<LocationAccess> requestAccess();

  /// Position of the user, or null when there is no permission, the GPS is
  /// off or it does not answer in time.
  Future<GeoPoint?> currentPosition();

  /// Opens the app settings so the user can unblock the permission.
  Future<bool> openSettings();
}

const _earthRadiusKm = 6371.0;

/// Straight-line distance between [a] and [b] in kilometres (haversine).
double distanceKm(GeoPoint a, GeoPoint b) {
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) *
          math.cos(rad(b.lat)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusKm * math.asin(math.min(1, math.sqrt(h)));
}
