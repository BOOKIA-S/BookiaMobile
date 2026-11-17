import 'package:bookia_mobile/core/location/geolocator_location_service.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlatform extends Mock implements GeolocatorPlatform {}

Position _position(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026, 11, 17),
  accuracy: 10,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late _MockPlatform platform;
  late GeolocatorLocationService service;

  setUpAll(() => registerFallbackValue(const LocationSettings()));

  setUp(() {
    platform = _MockPlatform();
    service = GeolocatorLocationService(
      platform: platform,
      timeout: const Duration(milliseconds: 50),
    );
  });

  void permission(LocationPermission value) =>
      when(platform.checkPermission).thenAnswer((_) async => value);

  group('checkAccess', () {
    for (final (permission: p, access: a) in [
      (permission: LocationPermission.always, access: LocationAccess.granted),
      (
        permission: LocationPermission.whileInUse,
        access: LocationAccess.granted,
      ),
      (permission: LocationPermission.denied, access: LocationAccess.denied),
      (
        permission: LocationPermission.unableToDetermine,
        access: LocationAccess.denied,
      ),
      (
        permission: LocationPermission.deniedForever,
        access: LocationAccess.deniedForever,
      ),
    ]) {
      test('$p is $a', () async {
        permission(p);
        expect(await service.checkAccess(), a);
      });
    }
  });

  group('requestAccess', () {
    test('shows the system dialog only while it can be shown', () async {
      permission(LocationPermission.denied);
      when(platform.requestPermission)
          .thenAnswer((_) async => LocationPermission.whileInUse);

      expect(await service.requestAccess(), LocationAccess.granted);
      verify(platform.requestPermission).called(1);
    });

    test('does not ask again when blocked or already granted', () async {
      permission(LocationPermission.deniedForever);
      expect(await service.requestAccess(), LocationAccess.deniedForever);
      permission(LocationPermission.always);
      expect(await service.requestAccess(), LocationAccess.granted);
      verifyNever(platform.requestPermission);
    });
  });

  group('currentPosition', () {
    setUp(() {
      permission(LocationPermission.whileInUse);
      when(platform.isLocationServiceEnabled).thenAnswer((_) async => true);
    });

    test('returns the GPS position', () async {
      when(
        () => platform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer((_) async => _position(20.17, -98.05));

      expect(await service.currentPosition(), (lat: 20.17, lng: -98.05));
    });

    test('is null without permission, without asking for it', () async {
      permission(LocationPermission.denied);
      expect(await service.currentPosition(), isNull);
      verifyNever(platform.requestPermission);
    });

    test('is null when the GPS is off', () async {
      when(platform.isLocationServiceEnabled).thenAnswer((_) async => false);
      expect(await service.currentPosition(), isNull);
    });

    test('falls back to the last known position on timeout', () async {
      when(
        () => platform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer(
        (_) =>
            Future.delayed(const Duration(seconds: 1), () => _position(0, 0)),
      );
      when(() => platform.getLastKnownPosition())
          .thenAnswer((_) async => _position(20.1, -98.0));

      expect(await service.currentPosition(), (lat: 20.1, lng: -98.0));
    });

    test('is null when the platform fails', () async {
      when(
        () => platform.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenThrow(const LocationServiceDisabledException());
      expect(await service.currentPosition(), isNull);
    });
  });

  test('openSettings opens the app settings', () async {
    when(platform.openAppSettings).thenAnswer((_) async => true);
    expect(await service.openSettings(), isTrue);
  });
}
