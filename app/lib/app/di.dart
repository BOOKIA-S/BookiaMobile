import 'package:bookia_mobile/core/offers/reservable_offer.dart';
import 'package:bookia_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:bookia_mobile/features/books/data/repositories/book_reservable_offer_source.dart';
import 'package:bookia_mobile/features/books/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Composition root (ARQ-04): the app wires the books feature into the shared
/// offer contract; the reservations feature depends only on the contract.
final reservableOfferSourceProvider = Provider<ReservableOfferSource>(
  (ref) => BookReservableOfferSource(ref.watch(bookRepositoryProvider)),
);

/// Shared sign-out contract for features that must close the session without
/// importing auth internals (for example the profile).
final signOutProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => ref.read(authControllerProvider.notifier).logout(),
);
