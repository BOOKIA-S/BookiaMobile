import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:bookia_mobile/core/utils/external_launcher.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';
import 'package:bookia_mobile/features/reservations/presentation/pages/reservation_ready_page.dart';
import 'package:bookia_mobile/features/reservations/presentation/providers.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/pickup_code_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'reservation_test_helpers.dart';

class _Launcher implements ExternalLauncher {
  final calls = <Uri>[];
  bool result = true;

  @override
  Future<bool> open(Uri uri) async {
    calls.add(uri);
    return result;
  }
}

Reservation _active({
  ReservationStatus status = const Pending(),
  DateTime? expiresAt,
}) => testReservation(
  id: 'abc4f7q',
  quantity: 2,
  status: status,
  expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 3)),
  book: const ReservationBook(id: 'b1', title: 'Aura', author: 'Carlos'),
  store: const ReservationStore(
    id: 's1',
    name: 'Librería del Centro',
    address: 'Calle Juárez 10',
  ),
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Reservation reservation, {
  _Launcher? launcher,
}) async {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      reservationRepositoryProvider.overrideWithValue(
        FakeReservationRepository(),
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
        home: ReservationReadyPage(
          reservationId: reservation.id,
          initial: reservation,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('an active reservation offers the reminder and opens it', (
    tester,
  ) async {
    final launcher = _Launcher();
    await _pump(tester, _active(), launcher: launcher);

    expect(find.text('Agregar recordatorio'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    await tester.tap(find.text('Agregar recordatorio'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'Abrir calendario'),
      findsOneWidget,
    );
    expect(find.textContaining('no lo guarda automáticamente'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Abrir calendario'));
    await tester.pumpAndSettle();
    expect(launcher.calls, hasLength(1));
    expect(launcher.calls.single.host, 'calendar.google.com');
    expect(find.textContaining('Revisa y guarda el evento'), findsOneWidget);
    expect(find.textContaining('Recordatorio guardado'), findsNothing);
  });

  testWidgets('a failed launcher keeps the screen and allows retry', (
    tester,
  ) async {
    final launcher = _Launcher()..result = false;
    await _pump(tester, _active(), launcher: launcher);

    await tester.tap(find.text('Agregar recordatorio'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Abrir calendario'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No pudimos abrir el calendario'),
      findsOneWidget,
    );
    expect(find.text('Agregar recordatorio'), findsOneWidget);
    expect(find.byType(PickupQr), findsOneWidget);
  });

  testWidgets('cancelled and expired reservations do not offer a reminder', (
    tester,
  ) async {
    await _pump(tester, _active(status: const Cancelled()));
    expect(find.text('Agregar recordatorio'), findsNothing);
  });

  testWidgets('a reservation about to expire explains the missing margin', (
    tester,
  ) async {
    final launcher = _Launcher();
    await _pump(
      tester,
      _active(expiresAt: DateTime.now().add(const Duration(minutes: 3))),
      launcher: launcher,
    );
    expect(find.text('Agregar recordatorio'), findsOneWidget);
    await tester.tap(find.text('Agregar recordatorio'));
    await tester.pumpAndSettle();
    expect(find.textContaining('vence demasiado pronto'), findsOneWidget);
    expect(launcher.calls, isEmpty);
  });
}
