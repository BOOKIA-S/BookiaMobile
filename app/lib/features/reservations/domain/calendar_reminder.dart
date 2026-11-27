import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';

/// Builds the Google Calendar request for screen 11. No new package: the
/// caller opens the HTTPS URI with `ExternalLauncher`.
///
/// The event starts one hour before the server expiry. If less than an hour
/// remains, it starts five minutes from now; if there is no reasonable margin
/// the builder returns null and the UI explains why. This lead time is an
/// implementation decision, not a SPECS.md requirement.
class CalendarReminder {
  CalendarReminder({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const leadTime = Duration(hours: 1);
  static const closeStart = Duration(minutes: 5);
  static const minimumMargin = Duration(minutes: 5);

  final DateTime Function() _now;

  Uri? build(Reservation reservation) {
    if (!reservation.status.isActive) return null;
    final now = _now().toUtc();
    final expiry = reservation.expiresAt.toUtc();
    if (!expiry.isAfter(now.add(minimumMargin))) return null;

    var start = expiry.subtract(leadTime);
    if (!start.isAfter(now)) start = now.add(closeStart);
    if (!start.isBefore(expiry)) return null;

    var end = start.add(const Duration(minutes: 30));
    if (end.isAfter(expiry)) end = expiry;
    if (!end.isAfter(start)) return null;

    final book = reservation.book;
    final store = reservation.store;
    final title = book == null || book.title.isEmpty
        ? 'Recoger reserva BOOKIA'
        : 'Recoger reserva BOOKIA: ${book.title}';
    final details = [
      '${reservation.quantity} '
          '${reservation.quantity == 1 ? 'ejemplar' : 'ejemplares'}',
      if (store != null && store.name.isNotEmpty) store.name,
      'Vence el ${_localDate(expiry)} a las ${_localTime(expiry)}',
      'Abre el evento en tu calendario y guárdalo. BOOKIA no lo guarda por ti.',
    ].join(' · ');

    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${_utcStamp(start)}/${_utcStamp(end)}',
      'details': details,
      if (store?.address case final address? when address.trim().isNotEmpty)
        'location': address,
    });
  }

  static String _utcStamp(DateTime value) {
    final utc = value.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}T'
        '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String _localDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day} de ${_months[local.month - 1]} de ${local.year}';
  }

  static String _localTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
