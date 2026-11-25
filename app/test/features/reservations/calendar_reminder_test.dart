import 'package:bookia_mobile/features/reservations/domain/calendar_reminder.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reservation_test_helpers.dart';

Reservation _active({
  String id = 'abc4f7q',
  String? title = 'Aura & Cía',
  String? storeName = 'Librería del Centro',
  String? address = 'Calle Juárez 10',
  DateTime? expiresAt,
  int quantity = 2,
  ReservationStatus status = const Pending(),
}) => testReservation(
  id: id,
  quantity: quantity,
  status: status,
  expiresAt: expiresAt ?? DateTime.utc(2026, 11, 25, 12),
  book: title == null
      ? null
      : ReservationBook(id: 'b1', title: title, author: 'Carlos Fuentes'),
  store: storeName == null
      ? null
      : ReservationStore(id: 's1', name: storeName, address: address),
);

CalendarReminder _at(DateTime now) => CalendarReminder(now: () => now);

Map<String, String> _query(Uri uri) => uri.queryParameters;

void main() {
  final now = DateTime.utc(2026, 11, 24, 12);

  test('builds an one-hour-before event with encoded data', () {
    final uri = _at(now).build(_active());
    expect(uri, isNotNull);
    expect(uri!.host, 'calendar.google.com');
    expect(uri.path, '/calendar/render');
    final query = _query(uri);
    expect(query['action'], 'TEMPLATE');
    expect(query['text'], 'Recoger reserva BOOKIA: Aura & Cía');
    expect(query['dates'], '20261125T110000Z/20261125T113000Z');
    expect(query['location'], 'Calle Juárez 10');
    expect(query['details'], contains('2 ejemplares'));
    expect(query['details'], contains('Librería del Centro'));
    expect(uri.toString(), contains('Aura+%26+C%C3%ADa'));
  });

  test('works with missing book and store', () {
    final uri = _at(now)
        .build(_active(title: null, storeName: null, address: null));
    final query = _query(uri!);
    expect(query['text'], 'Recoger reserva BOOKIA');
    expect(query.containsKey('location'), isFalse);
    expect(query['details'], contains('Vence el'));
  });

  test('starts five minutes from now when less than an hour remains', () {
    final uri = _at(DateTime.utc(2026, 11, 25, 11, 50)).build(_active());
    expect(_query(uri!)['dates'], '20261125T115500Z/20261125T120000Z');
  });

  test('refuses a reservation with less than five minutes left', () {
    expect(_at(DateTime.utc(2026, 11, 25, 11, 58)).build(_active()), isNull);
  });

  test('refuses inactive or expired reservations', () {
    for (final status in <ReservationStatus>[
      const Cancelled(),
      const Delivered(),
      const Expired(),
      const UnknownReservationStatus('otro'),
    ]) {
      expect(_at(now).build(_active(status: status)), isNull);
    }
    expect(_at(DateTime.utc(2026, 11, 25, 13)).build(_active()), isNull);
  });

  test('crosses a month boundary in UTC', () {
    final uri = _at(DateTime.utc(2026, 11, 30, 22))
        .build(_active(expiresAt: DateTime.utc(2026, 12, 1, 0, 30)));
    expect(_query(uri!)['dates'], '20261130T233000Z/20261201T000000Z');
  });

  test('never includes the reservation id or pickup code', () {
    final uri = _at(now).build(_active()).toString();
    expect(uri, isNot(contains('abc4f7q')));
    expect(uri, isNot(contains('BK-')));
    expect(uri, isNot(contains('@')));
  });
}
