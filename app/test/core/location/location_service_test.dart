import 'package:bookia_mobile/core/location/location_providers.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

void main() {
  group('distanceKm', () {
    test('is zero for the same point', () {
      const zocalo = (lat: 20.1767, lng: -98.0522);
      expect(distanceKm(zocalo, zocalo), 0);
    });

    test('matches the known distance Huauchinango - Puebla', () {
      const huauchinango = (lat: 20.1767, lng: -98.0522);
      const puebla = (lat: 19.0414, lng: -98.2063);
      expect(distanceKm(huauchinango, puebla), closeTo(127.2, 1));
    });
  });

  group('currentPositionProvider', () {
    late MockLocationService location;
    late ProviderContainer container;

    setUp(() {
      location = MockLocationService();
      container = ProviderContainer(
        overrides: [locationServiceProvider.overrideWithValue(location)],
      );
      addTearDown(container.dispose);
    });

    test('starts unknown and publishes a fresh position', () async {
      when(location.currentPosition)
          .thenAnswer((_) async => (lat: 20.17, lng: -98.05));
      expect(container.read(currentPositionProvider), isNull);

      await container.read(currentPositionProvider.notifier).refresh();
      expect(container.read(currentPositionProvider), (
        lat: 20.17,
        lng: -98.05,
      ));
    });

    test('keeps the last position when the GPS does not answer', () async {
      when(location.currentPosition)
          .thenAnswer((_) async => (lat: 1.0, lng: 2.0));
      final notifier = container.read(currentPositionProvider.notifier);
      await notifier.refresh();
      when(location.currentPosition).thenAnswer((_) async => null);

      expect(await notifier.refresh(), isNull);
      expect(container.read(currentPositionProvider), (lat: 1.0, lng: 2.0));
    });
  });
}
