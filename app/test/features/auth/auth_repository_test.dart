import 'package:bookia_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:bookia_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'login uses mobile contract and maps session seconds and user id',
    () async {
      String? path;
      Object? sentBody;
      final repository = AuthRepositoryImpl(
        AuthRemoteDataSource((requestPath, {body}) async {
          path = requestPath;
          sentBody = body;
          return {
            'user': {
              '_id': 'u1',
              'email': 'a@b.mx',
              'name': 'Ana',
              'role': 'store_owner',
              'store_id': 's1',
              'must_change_password': true,
              'created_at': '2026-11-09T12:00:00.000Z',
            },
            'token': 'secret',
            'expires_in': 28800,
          };
        }),
      );
      final session = await repository.login(
        'a@b.mx',
        'password123',
        staff: true,
      );
      expect(path, '/auth/login');
      expect(sentBody, {
        'email': 'a@b.mx',
        'password': 'password123',
        'client': 'mobile',
        'portal': 'admin',
      });
      expect(session.user.id, 'u1');
      expect(session.user.storeId, 's1');
      expect(session.user.mustChangePassword, isTrue);
      expect(session.expiresInSeconds, 28800);
    },
  );

  test('register sends only documented fields', () async {
    Object? sentBody;
    final remote = AuthRemoteDataSource((_, {body}) async {
      sentBody = body;
      return {
        'user': {
          '_id': 'u2',
          'email': 'a@b.mx',
          'name': 'Ana',
          'role': 'reader',
          'store_id': null,
          'must_change_password': false,
          'created_at': '2026-11-09T12:00:00Z',
        },
        'token': 'secret',
        'expires_in': 60,
      };
    });
    final session = await AuthRepositoryImpl(remote)
        .register('Ana', 'a@b.mx', 'password123');
    expect(sentBody, {
      'name': 'Ana',
      'email': 'a@b.mx',
      'password': 'password123',
      'client': 'mobile',
    });
    expect(session.user.role, 'reader');
    expect(session.user.storeId, isNull);
  });
}
