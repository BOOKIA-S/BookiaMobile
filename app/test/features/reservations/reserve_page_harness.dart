import 'package:bookia_mobile/app/di.dart';
import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:bookia_mobile/core/offers/reservable_offer.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/auth/presentation/providers.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/presentation/providers.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_test_helpers.dart';
import 'reservation_test_helpers.dart';

/// Pumps the real router and reserve screen with offline fakes.
Future<(ProviderContainer, GoRouter)> pumpReserve(
  WidgetTester tester, {
  String location = '/reserve/b1/o1',
  Book? book,
  ReservableOffer? offer,
  FakeReservationRepository? reservations,
  SessionStatus session = const GuestSession(),
  FakeAuthRepository? auth,
}) async {
  FlutterSecureStorage.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      bookRepositoryProvider.overrideWithValue(FakeBookRepository(book)),
      reservableOfferSourceProvider.overrideWithValue(
        FakeReservableOfferSource(offer: offer),
      ),
      reservationRepositoryProvider.overrideWithValue(
        reservations ?? FakeReservationRepository(),
      ),
      if (auth != null) authRepositoryProvider.overrideWithValue(auth),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentSessionProvider.notifier).set(session);
  final router = createRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (container, router);
}
