import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/core/storage/token_store.dart';
import 'package:bookia_mobile/features/splash/data/repositories/session_repository_impl.dart';
import 'package:bookia_mobile/features/splash/domain/entities/session_status.dart';
import 'package:bookia_mobile/features/splash/domain/repositories/session_repository.dart';
import 'package:bookia_mobile/features/splash/domain/usecases/check_stored_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  group('CheckStoredSession', () {
    late _MockSessionRepository repo;
    setUp(() {
      repo = _MockSessionRepository();
      when(repo.clearStoredToken).thenAnswer((_) async {});
    });

    test(
      'without a stored token opens as guest and never calls the API',
      () async {
        when(repo.hasStoredToken).thenAnswer((_) async => false);
        expect(await CheckStoredSession(repo)(), isA<GuestSession>());
        verifyNever(repo.fetchCurrentUser);
      },
    );

    test('with a valid token returns the signed-in user', () async {
      when(repo.hasStoredToken).thenAnswer((_) async => true);
      when(repo.fetchCurrentUser).thenAnswer(
        (_) async => const SignedInSession(name: 'Ana', role: 'reader'),
      );
      final status = await CheckStoredSession(repo)();
      expect(status, isA<SignedInSession>());
      expect((status as SignedInSession).name, 'Ana');
    });

    test('a 401 forgets the token and opens as guest', () async {
      when(repo.hasStoredToken).thenAnswer((_) async => true);
      when(repo.fetchCurrentUser).thenThrow(const UnauthorizedFailure());
      expect(await CheckStoredSession(repo)(), isA<GuestSession>());
      verify(repo.clearStoredToken).called(1);
    });

    test('offline opens as guest but keeps the token', () async {
      when(repo.hasStoredToken).thenAnswer((_) async => true);
      when(repo.fetchCurrentUser).thenThrow(const NetworkFailure());
      expect(await CheckStoredSession(repo)(), isA<GuestSession>());
      verifyNever(repo.clearStoredToken);
    });
  });

  group('SessionRepositoryImpl', () {
    test('reads the user of GET /auth/me', () async {
      final api = _MockApiClient();
      when(() => api.get<Map<String, dynamic>>('/auth/me')).thenAnswer(
        (_) async => {
          'user': {'_id': '1', 'name': 'Ana', 'role': 'reader'},
        },
      );
      final user = await SessionRepositoryImpl(
        api,
        MemoryTokenStore(),
      ).fetchCurrentUser();
      expect((user.name, user.role), ('Ana', 'reader'));
    });

    test('keeps the profile fields and the forced-change flag', () async {
      final api = _MockApiClient();
      when(() => api.get<Map<String, dynamic>>('/auth/me')).thenAnswer(
        (_) async => {
          'user': {
            '_id': 'u1',
            'email': 'ana@bookia.mx',
            'name': 'Ana',
            'role': 'store_owner',
            'store_id': 's1',
            'must_change_password': true,
            'created_at': '2026-11-09T12:00:00Z',
          },
        },
      );
      final user = await SessionRepositoryImpl(
        api,
        MemoryTokenStore(),
      ).fetchCurrentUser();
      expect(user.email, 'ana@bookia.mx');
      expect(user.storeId, 's1');
      expect(user.mustChangePassword, isTrue);
      expect(user.createdAt, DateTime.utc(2026, 11, 9, 12));
    });

    test('knows whether a token is stored and can clear it', () async {
      final tokens = MemoryTokenStore('jwt');
      final repo = SessionRepositoryImpl(_MockApiClient(), tokens);
      expect(await repo.hasStoredToken(), isTrue);
      await repo.clearStoredToken();
      expect(await repo.hasStoredToken(), isFalse);
      await tokens.write('');
      expect(await repo.hasStoredToken(), isFalse);
    });
  });
}
