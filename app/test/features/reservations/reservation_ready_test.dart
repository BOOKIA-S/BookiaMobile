import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/utils/external_launcher.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';
import 'package:bookia_mobile/features/reservations/presentation/formatters.dart';
import 'package:bookia_mobile/features/reservations/presentation/pages/reservation_ready_page.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/pickup_code_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'reservation_test_helpers.dart';

class FakeLauncher implements ExternalLauncher {
  final calls = <Uri>[];
  bool result = true;

  @override
  Future<bool> open(Uri uri) async {
    calls.add(uri);
    return result;
  }
}

const _book = ReservationBook(
  id: 'b1',
  title: 'Aura',
  author: 'Carlos Fuentes',
);
const _store = ReservationStore(
  id: 's1',
  name: 'Librería del Centro',
  address: 'Calle Juárez 10',
);

Reservation _reservation({
  String id = 'abc4f7q',
  ReservationStatus status = const Pending(),
  String? address = 'Calle Juárez 10',
  int quantity = 2,
}) => testReservation(
  id: id,
  price: 129,
  quantity: quantity,
  status: status,
  book: _book,
  store: address == null
      ? const ReservationStore(id: 's1', name: 'Librería del Centro')
      : _store,
);

Future<ProviderContainer> _pumpPage(
  WidgetTester tester, {
  String id = 'abc4f7q',
  Reservation? initial,
  FakeReservationRepository? reservations,
  FakeLauncher? launcher,
}) async {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      reservationRepositoryProvider.overrideWithValue(
        reservations ?? FakeReservationRepository(),
      ),
      if (launcher != null)
        externalLauncherProvider.overrideWithValue(launcher),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: ReservationReadyPage(reservationId: id, initial: initial),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('the short code is BK plus the last four characters', () {
    expect(_reservation().shortCode, 'BK-4F7Q');
    expect(testReservation(id: 'ab').shortCode, 'BK-AB');
  });

  test('statuses expose the actions allowed by PAT-10', () {
    for (final status in <ReservationStatus>[
      const Pending(),
      const Confirmed(),
    ]) {
      expect(status.isActive, isTrue);
      expect(status.canCancel, isTrue);
    }
    for (final (status, label) in <(ReservationStatus, String)>[
      (const Delivered(), 'Entregada'),
      (const Cancelled(), 'Cancelada'),
      (const Expired(), 'Vencida'),
    ]) {
      expect(status.isActive, isFalse);
      expect(status.canCancel, isFalse);
      expect(status.label, label);
    }
    const unknown = UnknownReservationStatus('en_revision');
    expect(unknown.raw, 'en_revision');
    expect(unknown.label, 'Estado desconocido');
    expect(unknown.isActive, isFalse);
  });

  test('the expiry label is written in local time', () {
    final utc = DateTime.utc(2026, 11, 19, 20, 5);
    final local = utc.toLocal();
    expect(formatDateTime(utc), startsWith('${local.day} de '));
    expect(formatDateTime(utc), endsWith(':05'));
  });

  testWidgets('screen 11 shows the code, QR and confirmed values', (
    tester,
  ) async {
    final reservations = FakeReservationRepository()
      ..onList = () async => [_reservation()];
    await _pumpPage(tester, reservations: reservations);

    expect(find.widgetWithText(AppBar, 'Reserva lista'), findsOneWidget);
    expect(find.text('¡Libro apartado!'), findsOneWidget);
    expect(find.text('BK-4F7Q'), findsOneWidget);
    expect(tester.widget<PickupQr>(find.byType(PickupQr)).data, 'abc4f7q');
    expect(find.text('Aura'), findsOneWidget);
    expect(find.text('Librería del Centro'), findsOneWidget);
    expect(find.text(r'$258.00'), findsOneWidget);
    expect(find.textContaining('Vence el '), findsOneWidget);
    expect(find.text('Cómo llegar'), findsOneWidget);
    expect(reservations.listCalls, 1);
  });

  testWidgets('a complete result from screen 10 needs no extra request', (
    tester,
  ) async {
    final reservations = FakeReservationRepository();
    await _pumpPage(
      tester,
      initial: _reservation(),
      reservations: reservations,
    );

    expect(find.text('¡Libro apartado!'), findsOneWidget);
    expect(find.text('BK-4F7Q'), findsOneWidget);
    expect(reservations.listCalls, 0);
  });

  testWidgets('an incomplete result is completed from /reservations/mine', (
    tester,
  ) async {
    final reservations = FakeReservationRepository()
      ..onList = () async => [_reservation()];
    await _pumpPage(
      tester,
      initial: testReservation(id: 'abc4f7q'),
      reservations: reservations,
    );

    expect(reservations.listCalls, 1);
    expect(find.text('Aura'), findsOneWidget);
    expect(tester.widget<PickupQr>(find.byType(PickupQr)).data, 'abc4f7q');
  });

  testWidgets('a cancelled reservation shows its status and no QR', (
    tester,
  ) async {
    final reservations = FakeReservationRepository()
      ..onList = () async => [_reservation(status: const Cancelled())];
    await _pumpPage(tester, reservations: reservations);

    expect(find.text('Reserva cancelada'), findsOneWidget);
    expect(find.text('Esta reserva ya no está activa.'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Aura'), findsOneWidget);
  });

  testWidgets('a missing reservation explains the problem', (tester) async {
    final reservations = FakeReservationRepository()..onList = () async => [];
    await _pumpPage(tester, reservations: reservations);

    expect(find.text('No encontramos esta reserva.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Reintentar'), findsOneWidget);
  });

  testWidgets('an expired session offers the login and returns to screen 11', (
    tester,
  ) async {
    final reservations = FakeReservationRepository();
    reservations.onList = () async => throw const UnauthorizedFailure();
    final container = ProviderContainer(
      overrides: [
        reservationRepositoryProvider.overrideWithValue(reservations),
      ],
    );
    addTearDown(container.dispose);
    final router = createRouter(initialLocation: '/reservation/abc4f7q');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.auth);
    expect(router.state.uri.queryParameters['next'], '/reservation/abc4f7q');
  });

  testWidgets('Cómo llegar opens a maps URI built from the store address', (
    tester,
  ) async {
    final launcher = FakeLauncher();
    final reservations = FakeReservationRepository()
      ..onList = () async => [_reservation()];
    await _pumpPage(tester, reservations: reservations, launcher: launcher);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cómo llegar'));
    await tester.pumpAndSettle();

    expect(launcher.calls, hasLength(1));
    final uri = launcher.calls.single;
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['query'], 'Calle Juárez 10');
  });

  testWidgets('without an address no map app is opened', (tester) async {
    final launcher = FakeLauncher();
    final reservations = FakeReservationRepository()
      ..onList = () async => [_reservation(address: null)];
    await _pumpPage(tester, reservations: reservations, launcher: launcher);

    expect(
      find.text('Esta librería no tiene dirección registrada.'),
      findsOneWidget,
    );
    expect(find.text('Cómo llegar'), findsNothing);
    expect(launcher.calls, isEmpty);
  });

  testWidgets('a launcher that cannot open maps shows an error', (
    tester,
  ) async {
    final launcher = FakeLauncher()..result = false;
    final reservations = FakeReservationRepository()
      ..onList = () async => [_reservation()];
    await _pumpPage(tester, reservations: reservations, launcher: launcher);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cómo llegar'));
    await tester.pumpAndSettle();

    expect(find.text('No hay una app para abrir el mapa.'), findsOneWidget);
  });
}
