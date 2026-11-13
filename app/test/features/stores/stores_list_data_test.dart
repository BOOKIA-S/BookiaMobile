import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/stores/data/dto/store_dto.dart';
import 'package:bookia_mobile/features/stores/data/mappers/store_mapper.dart';
import 'package:bookia_mobile/features/stores/data/repositories/store_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

Map<String, Object?> storeJson(String id, {num? distance}) => {
  '_id': id,
  'name': 'Librería $id',
  'address': 'Calle $id',
  'lat': 20.17,
  'lng': -98.05,
  'distance_km': ?distance,
};

void main() {
  late _MockApiClient api;
  late StoreRepositoryImpl repo;
  setUp(() {
    api = _MockApiClient();
    repo = StoreRepositoryImpl(api);
  });

  void answer(String path, List<Object?> body) =>
      when(() => api.get<List<dynamic>>(path, query: any(named: 'query')))
          .thenAnswer((_) async => body);

  test('without a position it calls GET /stores', () async {
    answer('/stores', [storeJson('a'), storeJson('b')]);

    final stores = await repo.getStores();

    expect(stores.map((s) => s.id), ['a', 'b']);
    expect(stores.first.name, 'Librería a');
    expect(stores.first.distanceKm, isNull);
    verifyNever(
      () => api.get<List<dynamic>>('/stores/near', query: any(named: 'query')),
    );
  });

  test(
    'with a position it calls /stores/near and keeps the distance',
    () async {
      answer('/stores/near', [
        storeJson('a', distance: 0.85),
        storeJson('b', distance: 1.3),
      ]);

      final stores = await repo.getStores(lat: 20.17, lng: -98.05);

      expect(stores.map((s) => s.distanceKm), [0.85, 1.3]);
      verify(
        () => api.get<List<dynamic>>(
          '/stores/near',
          query: {'lat': 20.17, 'lng': -98.05},
        ),
      ).called(1);
    },
  );

  test('a lone latitude is not enough to use /stores/near', () async {
    answer('/stores', [storeJson('a')]);

    await repo.getStores(lat: 20.17);

    verify(() => api.get<List<dynamic>>('/stores', query: any(named: 'query')))
        .called(1);
  });

  test('entries that are not objects are ignored', () async {
    answer('/stores', [storeJson('a'), 'garbage', null]);

    final stores = await repo.getStores();

    expect(stores, hasLength(1));
  });

  test('a Failure from the ApiClient reaches the caller', () {
    when(() => api.get<List<dynamic>>('/stores', query: any(named: 'query')))
        .thenThrow(const NetworkFailure());

    expect(repo.getStores(), throwsA(isA<NetworkFailure>()));
  });

  test('optional fields may be missing', () {
    final store = StoreDto.fromJson({'_id': 's2', 'name': 'Escolar'})
        .toEntity();

    expect(store.address, '');
    expect(store.phone, isNull);
    expect(store.lat, isNull);
    expect(store.distanceKm, isNull);
  });
}
