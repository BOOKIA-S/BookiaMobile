import 'package:bookia_mobile/app/push_links.dart';
import 'package:flutter_test/flutter_test.dart';

const _id = '65a1b2c3d4e5f6a7b8c9d0e1';

void main() {
  test('reservation_id opens screen 11', () {
    expect(routeForPush({'reservation_id': _id}), '/reservation/$_id');
  });

  test('reservation_id wins over book_id', () {
    expect(
      routeForPush({'reservation_id': _id, 'book_id': _id}),
      '/reservation/$_id',
    );
  });

  test('book_id opens screen 07', () {
    expect(routeForPush({'book_id': _id}), '/books/$_id');
  });

  test('type reservation without id opens screen 12', () {
    expect(routeForPush({'type': 'reservation'}), '/reservations');
  });

  test('ids that are not Mongo ids never become routes', () {
    expect(routeForPush({'reservation_id': '../staff'}), isNull);
    expect(routeForPush({'book_id': 'https://evil.test'}), isNull);
    expect(routeForPush({'book_id': '${_id}0'}), isNull);
    expect(routeForPush({}), isNull);
  });
}
