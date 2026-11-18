import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';
import 'package:bookia_mobile/features/staff/data/datasources/staff_remote_data_source.dart';
import 'package:bookia_mobile/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

Map<String, Object?> reservationJson(
  String id, {
  String status = 'pendiente',
}) => {
  '_id': id,
  'offer_id': 'o1',
  'user_id': 'u1',
  'store_id': 's1',
  'book_id': 'b1',
  'price': 75,
  'quantity': 2,
  'status': status,
  'expires_at': '2026-11-20T18:00:00.000Z',
  'created_at': '2026-11-17T18:00:00.000Z',
  'book': {'_id': 'b1', 'title': 'Pedro Páramo', 'author': 'Juan Rulfo'},
  'store': {'_id': 's1', 'name': 'Librería Azalea'},
};

Map<String, Object?> meJson({
  String role = 'store_owner',
  String? storeId = 's1',
  bool mustChange = false,
}) => {
  'user': {
    '_id': 'u1',
    'name': 'Karol',
    'role': role,
    'store_id': storeId,
    'must_change_password': mustChange,
  },
};

void main() {
  late _MockApiClient api;
  late StaffRepositoryImpl repo;
  setUp(() {
    api = _MockApiClient();
    repo = StaffRepositoryImpl(StaffRemoteDataSource(api));
  });

  void answerMe(Map<String, Object?> body) =>
      when(() => api.get<Map<String, dynamic>>('/auth/me'))
          .thenAnswer((_) async => body);

  void answerManage(Map<String, Object?> body) =>
      when(() => api.get<Map<String, dynamic>>('/reservations/manage'))
          .thenAnswer((_) async => body);

  group('getProfile', () {
    test('GET /auth/me gives the account and its store', () async {
      answerMe(meJson());

      final profile = await repo.getProfile();

      expect(profile.name, 'Karol');
      expect(profile.role, 'store_owner');
      expect(profile.storeId, 's1');
      expect(profile.mustChangePassword, isFalse);
      expect(profile.isAdmin, isFalse);
    });

    test('an admin has no store and a flag can block the desk', () async {
      answerMe(meJson(role: 'admin', storeId: null, mustChange: true));

      final profile = await repo.getProfile();

      expect(profile.isAdmin, isTrue);
      expect(profile.storeId, isNull);
      expect(profile.mustChangePassword, isTrue);
    });

    test('a response without user is a ServerFailure', () {
      answerMe({'message': 'oops'});

      expect(repo.getProfile(), throwsA(isA<ServerFailure>()));
    });
  });

  group('listReservations', () {
    test('GET /reservations/manage is mapped with book and status', () async {
      answerManage({
        'items': [
          reservationJson('r1'),
          reservationJson('r2', status: 'confirmada'),
        ],
      });

      final list = await repo.listReservations();

      expect(list.map((r) => r.id), ['r1', 'r2']);
      expect(list.first.status, isA<Pending>());
      expect(list.last.status, isA<Confirmed>());
      expect(list.first.book?.title, 'Pedro Páramo');
      expect(list.first.total, 150);
    });

    test(
      'a body without items or with a bad item is a ServerFailure',
      () async {
        answerManage({'message': 'oops'});
        await expectLater(
          repo.listReservations(),
          throwsA(isA<ServerFailure>()),
        );

        answerManage({
          'items': ['garbage'],
        });
        await expectLater(
          repo.listReservations(),
          throwsA(isA<ServerFailure>()),
        );
      },
    );

    test('a Failure from the ApiClient reaches the caller', () {
      when(() => api.get<Map<String, dynamic>>('/reservations/manage'))
          .thenThrow(const PasswordChangeRequiredFailure());

      expect(
        repo.listReservations(),
        throwsA(isA<PasswordChangeRequiredFailure>()),
      );
    });
  });

  group('confirm and reject', () {
    void answerPatch(String id, String sent, String received) => when(
      () => api.patch<Map<String, dynamic>>(
        '/reservations/$id/status',
        body: {'status': sent},
      ),
    ).thenAnswer((_) async => reservationJson(id, status: received));

    test('confirm sends confirmada', () async {
      answerPatch('r1', 'confirmada', 'confirmada');

      final reservation = await repo.confirm('r1');

      expect(reservation.status, isA<Confirmed>());
      verify(
        () => api.patch<Map<String, dynamic>>(
          '/reservations/r1/status',
          body: {'status': 'confirmada'},
        ),
      ).called(1);
    });

    test('reject sends cancelada', () async {
      answerPatch('r1', 'cancelada', 'cancelada');

      final reservation = await repo.reject('r1');

      expect(reservation.status, isA<Cancelled>());
    });

    test('the desk errors are translated to Spanish', () async {
      final cases = <Failure, Matcher>{
        const ConflictFailure(
          'Reservation cannot change',
        ): isA<ConflictFailure>().having(
          (f) => f.message,
          'message',
          contains('cambió de estado'),
        ),
        const NotFoundFailure('Reservation not found'): isA<NotFoundFailure>()
            .having((f) => f.message, 'message', contains('ya no está')),
        const ValidationFailure('Invalid status'): isA<ValidationFailure>()
            .having((f) => f.message, 'message', contains('No pudimos')),
        const ForbiddenFailure(): isA<ForbiddenFailure>(),
      };
      for (final entry in cases.entries) {
        when(
          () => api.patch<Map<String, dynamic>>(
            '/reservations/r1/status',
            body: any(named: 'body'),
          ),
        ).thenThrow(entry.key);

        await expectLater(repo.confirm('r1'), throwsA(entry.value));
      }
    });
  });
}
