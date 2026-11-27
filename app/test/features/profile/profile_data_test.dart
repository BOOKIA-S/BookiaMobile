import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:bookia_mobile/features/profile/data/dto/profile_user_dto.dart';
import 'package:bookia_mobile/features/profile/data/mappers/profile_user_mapper.dart';
import 'package:bookia_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

Map<String, dynamic> _user({
  String name = 'Ana',
  bool mustChangePassword = false,
}) => {
  'user': {
    '_id': 'u1',
    'email': 'ana@bookia.mx',
    'name': name,
    'role': 'reader',
    'store_id': null,
    'must_change_password': mustChangePassword,
    'created_at': '2026-11-09T12:00:00.000Z',
  },
};

void main() {
  group('ProfileUserDto', () {
    test('maps the full user object', () {
      final user = ProfileUserDto.fromJson(_user()).toDomain();
      expect(
        (user.id, user.email, user.name, user.role),
        ('u1', 'ana@bookia.mx', 'Ana', 'reader'),
      );
      expect(user.storeId, isNull);
      expect(user.mustChangePassword, isFalse);
      expect(user.createdAt, DateTime.utc(2026, 11, 9, 12));
    });

    test('rejects a response without a user object', () {
      expect(
        () => ProfileUserDto.fromJson({'ok': true}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ProfileRepositoryImpl', () {
    test('GET /auth/me maps the account', () async {
      final adapter = FakeHttpAdapter(200, _user());
      final repository = ProfileRepositoryImpl(
        ProfileRemoteDataSource(fakeApiClient(adapter)),
      );
      final user = await repository.me();
      expect(adapter.last!.method, 'GET');
      expect(adapter.last!.uri.path, '/api/auth/me');
      expect(user.name, 'Ana');
    });

    test('PATCH /auth/me sends only the name', () async {
      final adapter = FakeHttpAdapter(200, _user(name: 'Ana María'));
      final repository = ProfileRepositoryImpl(
        ProfileRemoteDataSource(fakeApiClient(adapter)),
      );
      final user = await repository.updateName('Ana María');
      expect(adapter.last!.method, 'PATCH');
      expect(adapter.last!.data, {'name': 'Ana María'});
      expect(user.name, 'Ana María');
    });

    test('PATCH /auth/password sends both passwords', () async {
      final adapter = FakeHttpAdapter(200, _user());
      final repository = ProfileRepositoryImpl(
        ProfileRemoteDataSource(fakeApiClient(adapter)),
      );
      await repository.changePassword(
        currentPassword: 'current123',
        newPassword: 'newpass123',
      );
      expect(adapter.last!.data, {
        'current_password': 'current123',
        'new_password': 'newpass123',
      });
    });

    test('counts only pending/confirmed reservations before expiry', () async {
      final adapter = FakeHttpAdapter(200, {
        'items': [
          {'status': 'pendiente', 'expires_at': '2026-11-25T12:00:00Z'},
          {'status': 'confirmada', 'expires_at': '2026-11-25T12:00:00Z'},
          {'status': 'pendiente', 'expires_at': '2026-11-20T12:00:00Z'},
          {'status': 'cancelada', 'expires_at': '2026-11-25T12:00:00Z'},
          {'status': 'entregada', 'expires_at': '2026-11-25T12:00:00Z'},
          {'status': 'vencida', 'expires_at': '2026-11-25T12:00:00Z'},
          {'status': 'otro', 'expires_at': '2026-11-25T12:00:00Z'},
          {'status': 'pendiente', 'expires_at': 'not-a-date'},
        ],
      });
      final repository = ProfileRepositoryImpl(
        ProfileRemoteDataSource(fakeApiClient(adapter)),
        now: () => DateTime.utc(2026, 11, 24),
      );
      expect(await repository.activeReservationCount(), 2);
    });

    test('a malformed profile response becomes ServerFailure', () async {
      final adapter = FakeHttpAdapter(200, {'user': 'nope'});
      final repository = ProfileRepositoryImpl(
        ProfileRemoteDataSource(fakeApiClient(adapter)),
      );
      await expectLater(repository.me(), throwsA(isA<ServerFailure>()));
    });
  });
}
