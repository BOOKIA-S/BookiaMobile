import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:bookia_mobile/features/reservations/data/dto/reservation_dto.dart';
import 'package:bookia_mobile/features/reservations/data/repositories/reservation_repository_impl.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

Map<String, dynamic> _created({Object? book, Object? store}) => {
  '_id': 'r1',
  'user_id': 'u1',
  'offer_id': 'o1',
  'store_id': 's1',
  'book_id': 'b1',
  'price': 129,
  'quantity': 2,
  'status': 'pendiente',
  'expires_at': '2026-11-19T20:00:00.000Z',
  'created_at': '2026-11-17T20:00:00.000Z',
  'updated_at': '2026-11-17T20:00:00.000Z',
  'book': ?book,
  'store': ?store,
};

ReservationRepositoryImpl _repository(FakeHttpAdapter adapter) =>
    ReservationRepositoryImpl(
      ReservationRemoteDataSource(fakeApiClient(adapter)),
    );

void main() {
  test(
    'POST /reservations sends the contract and parses the 201 body',
    () async {
      final adapter = FakeHttpAdapter(201, _created());
      final reservation = await _repository(adapter)
          .create(offerId: 'o1', quantity: 2);

      expect(adapter.last!.method, 'POST');
      expect(adapter.last!.uri.path, '/api/reservations');
      expect(adapter.last!.data, {'offer_id': 'o1', 'quantity': 2});
      expect(reservation.id, 'r1');
      expect(reservation.quantity, 2);
      expect(reservation.price, 129);
      expect(reservation.total, 258);
      expect(reservation.status, isA<Pending>());
      expect(reservation.expiresAt, DateTime.utc(2026, 11, 19, 20));
      expect(reservation.book, isNull);
      expect(reservation.store, isNull);
    },
  );

  test('GET /reservations/mine reads populated book and store', () async {
    final adapter = FakeHttpAdapter(200, {
      'items': [
        _created(
          book: {'_id': 'b1', 'title': 'Aura', 'author': 'Carlos Fuentes'},
          store: {
            '_id': 's1',
            'name': 'Librería del Centro',
            'address': 'Calle Juárez 10',
            'phone': '7761234567',
            'schedule': 'Lun a sáb',
          },
        ),
      ],
    });
    final items = await _repository(adapter).listMine();

    expect(items, hasLength(1));
    expect(items.single.book!.title, 'Aura');
    expect(items.single.book!.author, 'Carlos Fuentes');
    expect(items.single.store!.name, 'Librería del Centro');
    expect(items.single.store!.address, 'Calle Juárez 10');
    expect(items.single.store!.phone, '7761234567');
    expect(items.single.store!.schedule, 'Lun a sáb');
  });

  test('API errors become Spanish failures', () async {
    final cases = <(int, Map<String, dynamic>, Matcher, String?)>[
      (
        400,
        {'message': 'You can have up to 10 active reservations'},
        isA<ValidationFailure>(),
        '10 reservas activas',
      ),
      (
        400,
        {'message': 'quantity must be an integer from 1 to 5'},
        isA<ValidationFailure>(),
        '1 a 5 ejemplares',
      ),
      (
        400,
        {'message': 'Invalid offer_id'},
        isA<ValidationFailure>(),
        'oferta',
      ),
      (
        409,
        {'message': 'Not enough copies available'},
        isA<ConflictFailure>(),
        'Ya no hay suficientes ejemplares',
      ),
      (
        404,
        {'message': 'Offer not found'},
        isA<NotFoundFailure>(),
        'ya no está disponible',
      ),
      (401, {'message': 'Invalid session'}, isA<UnauthorizedFailure>(), null),
      (403, {'message': 'Forbidden'}, isA<ForbiddenFailure>(), null),
      (500, {'message': 'boom'}, isA<ServerFailure>(), null),
    ];
    for (final (status, body, matcher, message) in cases) {
      await expectLater(
        _repository(FakeHttpAdapter(status, body))
            .create(offerId: 'o1', quantity: 1),
        throwsA(
          message == null
              ? matcher
              : allOf(
                  matcher,
                  predicate<Failure>((f) => f.message.contains(message)),
                ),
        ),
      );
    }
  });

  test('a body without the contract fields is a ServerFailure', () async {
    final missingId = _created()..remove('_id');
    final missingOffer = _created()..remove('offer_id');
    for (final body in <Map<String, dynamic>>[
      missingId,
      {..._created(), 'price': 'free'},
      {..._created(), 'quantity': 0},
      {..._created(), 'quantity': 1.5},
      {..._created(), 'quantity': 2.7},
      {..._created(), 'quantity': '2'},
      {..._created(), 'quantity': 6},
      {..._created(), 'quantity': -1},
      {..._created(), 'quantity': null},
      {..._created(), 'status': 7},
      {..._created(), 'expires_at': 'not-a-date'},
      missingOffer,
    ]) {
      await expectLater(
        _repository(FakeHttpAdapter(201, body))
            .create(offerId: 'o1', quantity: 1),
        throwsA(isA<ServerFailure>()),
      );
    }
  });

  test('ids are also accepted as { _id } references', () async {
    final reservation = await _repository(
      FakeHttpAdapter(201, {
        ..._created(),
        'offer_id': {'_id': 'o1'},
        'store_id': {'_id': 's1'},
        'book_id': {'_id': 'b1'},
      }),
    ).create(offerId: 'o1', quantity: 1);

    expect(reservation.offerId, 'o1');
    expect(reservation.storeId, 's1');
    expect(reservation.bookId, 'b1');
  });

  test('GET /reservations/mine rejects a body without items', () async {
    await expectLater(
      _repository(FakeHttpAdapter(200, {'items': 'none'})).listMine(),
      throwsA(isA<ServerFailure>()),
    );
  });

  test('non-finite or fractional quantities and prices are rejected', () {
    for (final body in <Map<String, dynamic>>[
      {..._created(), 'quantity': double.nan},
      {..._created(), 'quantity': double.infinity},
      {..._created(), 'price': double.nan},
    ]) {
      expect(
        () => ReservationDto.fromJson(body),
        throwsA(isA<FormatException>()),
        reason: '$body',
      );
    }
  });

  test('every item of /mine must be a map', () async {
    for (final item in <Object?>[
      null,
      'text',
      42,
      {'not': 'a reservation'},
    ]) {
      await expectLater(
        _repository(
          FakeHttpAdapter(200, {
            'items': [item],
          }),
        ).listMine(),
        throwsA(isA<ServerFailure>()),
        reason: '$item',
      );
    }
    await expectLater(
      _repository(
        FakeHttpAdapter(200, {
          'items': [_created(), null],
        }),
      ).listMine(),
      throwsA(isA<ServerFailure>()),
    );
    final valid = await _repository(
      FakeHttpAdapter(200, {
        'items': [_created()],
      }),
    ).listMine();
    expect(valid, hasLength(1));
  });

  test('the five API statuses map, and unknown ones are kept', () async {
    for (final (raw, expected) in [
      ('pendiente', isA<Pending>()),
      ('confirmada', isA<Confirmed>()),
      ('entregada', isA<Delivered>()),
      ('cancelada', isA<Cancelled>()),
      ('vencida', isA<Expired>()),
      ('en_revision', isA<UnknownReservationStatus>()),
    ]) {
      final reservation = await _repository(
        FakeHttpAdapter(201, {..._created(), 'status': raw}),
      ).create(offerId: 'o1', quantity: 1);
      expect(reservation.status, expected);
    }
    final unknown = await _repository(
      FakeHttpAdapter(201, {..._created(), 'status': 'en_revision'}),
    ).create(offerId: 'o1', quantity: 1);
    expect((unknown.status as UnknownReservationStatus).raw, 'en_revision');
  });
}
