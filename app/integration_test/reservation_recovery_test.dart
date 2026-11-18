import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/storage/token_storage.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/pickup_code_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'reserve_flow_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(requireIntegrationConfig);

  testWidgets('an existing reservation opens screen 11 without new POSTs', (
    tester,
  ) async {
    final api = integrationClient();
    final setupToken = await integrationToken(api);
    final books = (await api.get<Map<String, dynamic>>(
      '/books',
      queryParameters: {'limit': 100},
    )).data!;
    final offer = availableOffer(books)['offer'] as Map<String, dynamic>;
    final created = await createReservation(
      api,
      setupToken,
      offer['_id'] as String,
      1,
    );
    final reservationId = created['_id'] as String;

    try {
      await const TokenStorage().saveToken(setupToken);
      final mine = await myReservations(api, setupToken);
      final reservation = mine.firstWhere((r) => r['_id'] == reservationId);
      final container = ProviderContainer(
        overrides: [apiBaseUrlProvider.overrideWithValue(apiBaseUrl)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: createRouter(
              initialLocation: '/reservation/$reservationId?recovered=1',
            ),
          ),
        ),
      );
      await pumpUntil(tester, find.byType(PickupQr));

      expect(find.text('Reserva encontrada'), findsOneWidget);
      expect(find.text('¡Libro apartado!'), findsNothing);
      expect(
        tester.widget<PickupQr>(find.byType(PickupQr)).data,
        reservationId,
      );
      expect(find.text(reservation['book']['title'] as String), findsOneWidget);
    } finally {
      await cancelReservation(api, setupToken, reservationId);
      await clearTestToken();
    }
  });
}
