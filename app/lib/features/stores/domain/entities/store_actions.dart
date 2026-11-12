import 'package:bookia_mobile/features/stores/domain/entities/store.dart';

/// Links the user can follow from a store: call it and get directions.
extension StoreActions on Store {
  /// `tel:` link with only digits (and a leading `+`), or null with no phone.
  Uri? get callUri {
    final digits = phone?.replaceAll(RegExp('[^0-9+]'), '') ?? '';
    return digits.isEmpty ? null : Uri(scheme: 'tel', path: digits);
  }

  /// Google Maps route to the store: by coordinates when known, else by
  /// address. Google Maps links open the Maps app on Android and iOS.
  Uri get directionsUri {
    final latitude = lat;
    final longitude = lng;
    final destination = latitude != null && longitude != null
        ? '$latitude,$longitude'
        : address;
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
  }
}
