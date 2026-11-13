import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/stores/data/dto/store_detail_dto.dart';
import 'package:bookia_mobile/features/stores/data/mappers/store_detail_mapper.dart';
import 'package:bookia_mobile/features/stores/data/repositories/store_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

Map<String, Object?> offerJson(String id, {int stock = 6, num price = 75}) => {
  '_id': id,
  'price': price,
  'stock': stock,
  'is_available': stock > 0,
  'book': {'_id': 'b-$id', 'title': 'Pedro Páramo', 'author': 'Juan Rulfo'},
};

Map<String, Object?> storeJson({List<Object?>? offers}) => {
  '_id': 's1',
  'name': 'Librería Azalea',
  'address': 'Av. Benito Juárez 112',
  'phone': '776 762 0145',
  'schedule': 'Lun–Sáb 9:00–20:00',
  'maps_url': 'https://maps.example/azalea',
  'lat': 20.17,
  'lng': -98.05,
  'offers': offers ?? [offerJson('o1'), offerJson('o2', stock: 0)],
};

void main() {
  test('GET /stores/:id is mapped into a StoreDetail', () async {
    final api = _MockApiClient();
    when(() => api.get<Map<String, dynamic>>('/stores/s1'))
        .thenAnswer((_) async => storeJson());

    final detail = await StoreRepositoryImpl(api).getStore('s1');

    expect(detail.store.name, 'Librería Azalea');
    expect(detail.store.phone, '776 762 0145');
    expect(detail.store.lat, 20.17);
    expect(detail.offers, hasLength(2));
    expect(detail.offers.first.title, 'Pedro Páramo');
    expect(detail.offers.first.price, 75.0);
    expect(detail.offers.first.isAvailable, isTrue);
    expect(detail.offers.last.isAvailable, isFalse);
  });

  test('a Failure from the ApiClient reaches the caller', () {
    final api = _MockApiClient();
    when(() => api.get<Map<String, dynamic>>('/stores/x'))
        .thenThrow(const NotFoundFailure());

    expect(
      StoreRepositoryImpl(api).getStore('x'),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('optional fields may be missing and offers default to empty', () {
    final dto = StoreDetailDto.fromJson({'_id': 's2', 'name': 'Escolar'});
    final detail = dto.toEntity();

    expect(detail.store.address, '');
    expect(detail.store.phone, isNull);
    expect(detail.store.schedule, isNull);
    expect(detail.store.mapsUrl, isNull);
    expect(detail.store.lat, isNull);
    expect(detail.offers, isEmpty);
  });

  test('low stock is 1 or 2 copies; sold out is never low', () {
    StoreDetailDto withStock(int stock) => StoreDetailDto.fromJson(
      storeJson(offers: [offerJson('o', stock: stock)]),
    );
    bool low(int stock) => withStock(stock).toEntity().offers.single.isLowStock;

    expect(low(6), isFalse);
    expect(low(2), isTrue);
    expect(low(1), isTrue);
    expect(low(0), isFalse);
  });
}
