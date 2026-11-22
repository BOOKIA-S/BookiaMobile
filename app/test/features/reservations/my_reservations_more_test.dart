import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';
import 'package:bookia_mobile/features/reservations/presentation/pages/my_reservations_page.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/expiry_countdown.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/reservation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'reservation_test_helpers.dart';

final now = DateTime.utc(2026, 11, 23, 12);

const aura = ReservationBook(id: 'b1', title: 'Aura', author: 'Carlos Fuentes');
const centro = ReservationStore(id: 's1', name: 'Librería del Centro');

Reservation mine(String id, ReservationStatus status) => testReservation(
  id: id,
  status: status,
  expiresAt: now.add(const Duration(hours: 30)),
  book: aura,
  store: centro,
);

void main() {
  late FakeReservationRepository repo;
  setUp(() => repo = FakeReservationRepository());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [reservationRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: MyReservationsPage(now: () => now)),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('each status has its color (PAT-10)', () {
    expect(statusColor(const Pending()), AppColors.warning);
    expect(statusColor(const Confirmed()), AppColors.success);
    expect(statusColor(const Delivered()), AppColors.success);
    for (final s in const [
      Cancelled(),
      Expired(),
      UnknownReservationStatus('en_ruta'),
    ]) {
      expect(statusColor(s), AppColors.textSecondary, reason: s.label);
    }
  });

  testWidgets('history lists finished reservations without actions', (
    tester,
  ) async {
    repo.onList = () async => [
      mine('aaaaa1', const Delivered()),
      mine('bbbbb2', const Cancelled()),
      mine('ccccc3', const Expired()),
    ];
    await pump(tester);
    expect(find.text('Activas (0)'), findsOneWidget);

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    for (final label in ['Entregada', 'Cancelada', 'Vencida']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Cancelar'), findsNothing);
    expect(find.text('Ver código'), findsNothing);
    expect(find.byType(ExpiryCountdown), findsNothing);
  });

  testWidgets('an empty history explains what will appear', (tester) async {
    repo.onList = () async => [mine('aaaaa1', const Pending())];
    await pump(tester);
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aquí verás las reservas'), findsOneWidget);
  });

  testWidgets('the countdown refreshes and turns red under 6 hours', (
    tester,
  ) async {
    var clock = now;
    await tester.pumpWidget(
      MaterialApp(
        home: ExpiryCountdown(
          expiresAt: now.add(const Duration(hours: 6, minutes: 1)),
          now: () => clock,
        ),
      ),
    );
    final error = Theme.of(tester.element(find.byType(ExpiryCountdown)))
        .colorScheme
        .error;
    Color? colorOf(String text) =>
        tester.widget<Text>(find.text(text)).style?.color;

    expect(colorOf('Vence en 6 h 1 min'), isNot(error));

    clock = clock.add(const Duration(minutes: 2));
    await tester.pump(const Duration(minutes: 1));
    expect(colorOf('Vence en 5 h 59 min'), error);
  });

  testWidgets('Ver código opens screen 11 with the reservation', (
    tester,
  ) async {
    repo.onList = () async => [mine('aaaaa1', const Confirmed())];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MyReservationsPage(now: () => now),
        ),
        GoRoute(
          path: '/reservation/:id',
          builder: (_, state) => Text(
            'Pantalla 11 ${state.pathParameters['id']} '
            '${(state.extra! as Reservation).shortCode}',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [reservationRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver código'));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla 11 aaaaa1 BK-AAA1'), findsOneWidget);
  });

  testWidgets('a rejected cancel shows why and keeps the reservation', (
    tester,
  ) async {
    repo.onList = () async => [mine('aaaaa1', const Pending())];
    repo.onCancel = (_) => Future.error(
      const ConflictFailure('Esta reserva ya no se puede cancelar.'),
    );
    await pump(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Esta reserva ya no se puede cancelar.'), findsOneWidget);
    expect(find.text('Activas (1)'), findsOneWidget);
  });

  testWidgets('a load error offers Reintentar', (tester) async {
    repo.onList = () => Future.error(const NetworkFailure());
    await pump(tester);
    expect(find.text(const NetworkFailure().message), findsOneWidget);

    repo.onList = () async => [mine('aaaaa1', const Pending())];
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Activas (1)'), findsOneWidget);
  });
}
