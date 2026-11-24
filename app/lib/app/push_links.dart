import 'package:bookia_mobile/app/router.dart';

/// Mongo ids are 24 hex characters; anything else is ignored, so a push
/// payload can never open an arbitrary route.
final _objectId = RegExp(r'^[a-fA-F0-9]{24}$');

/// Deep link of a push (screen 13): `reservation_id` opens 11 for that
/// reservation, `book_id` opens 07 ("¡Ya llegó!"), and `type: reservation`
/// without an id opens 12. Null when the payload has no valid link.
String? routeForPush(Map<String, String> data) {
  final reservationId = data['reservation_id'];
  if (reservationId != null && _objectId.hasMatch(reservationId)) {
    return AppRoutes.reservationReady(reservationId);
  }
  final bookId = data['book_id'];
  if (bookId != null && _objectId.hasMatch(bookId)) {
    return AppRoutes.book(bookId);
  }
  if (data['type'] == 'reservation') return AppRoutes.reservations;
  return null;
}
