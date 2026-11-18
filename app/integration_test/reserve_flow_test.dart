import 'package:bookia_mobile/core/storage/token_storage.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/pickup_code_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'reserve_flow_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(requireIntegrationConfig);

  testWidgets('guest reserves and the new reservation is distinguishable', (
    tester,
  ) async {
    final api = integrationClient();
    final setupToken = await integrationToken(api);
    final books = (await api.get<Map<String, dynamic>>(
      '/books',
      queryParameters: {'limit': 100},
    )).data!;
    final pick = availableOffer(books);
    final book = pick['book'] as Map<String, dynamic>;
    final offer = pick['offer'] as Map<String, dynamic>;
    final offerId = offer['_id'] as String;
    final price = (offer['price'] as num).toDouble();
    final initialStock = (offer['stock'] as num).toInt();
    const quantity = 2;

    // A previous active reservation of the same offer must never be mistaken
    // for the one created by the flow.
    final old = await createReservation(api, setupToken, offerId, 1);
    final oldId = old['_id'] as String;
    final beforeFlowIds = reservationIds(await myReservations(api, setupToken));
    final flowStart = DateTime.now().toUtc();
    String? newId;

    try {
      await clearTestToken();
      await installApp(tester, book['_id'] as String);
      await loginAndReserve(tester, quantity: quantity);

      final token = await const TokenStorage().readToken();
      expect(token, isNotNull);
      final mine = await myReservations(api, token!);
      final created = mine
          .where(
            (r) =>
                !beforeFlowIds.contains(r['_id']) &&
                r['offer_id'] == offerId &&
                r['status'] == 'pendiente' &&
                DateTime.parse(r['created_at'] as String)
                    .isAfter(flowStart.subtract(const Duration(seconds: 5))),
          )
          .toList();
      expect(created, hasLength(1));
      newId = created.single['_id'] as String;
      expect(newId, isNot(oldId));
      expect(created.single['quantity'], quantity);

      expect(tester.widget<PickupQr>(find.byType(PickupQr)).data, newId);
      expect(
        find.text('BK-${newId.substring(newId.length - 4).toUpperCase()}'),
        findsOneWidget,
      );
      expect(created.single['price'], price);

      final booksAfter = (await api.get<Map<String, dynamic>>(
        '/books',
        queryParameters: {'limit': 100},
      )).data!;
      final bookAfter = (booksAfter['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((b) => b['_id'] == book['_id']);
      final offerAfter = (bookAfter['offers'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((o) => o['_id'] == offerId);
      expect(offerAfter['stock'], initialStock - 1 - quantity);
    } finally {
      // Cancel only what this run created. If the new id was not captured,
      // recover it by exclusion and creation time for the dedicated account.
      final cleanupIds = <String>{?newId};
      if (newId == null) {
        try {
          final mine = await myReservations(api, setupToken);
          cleanupIds.addAll(
            mine
                .where(
                  (r) =>
                      !beforeFlowIds.contains(r['_id']) &&
                      r['offer_id'] == offerId &&
                      DateTime.parse(
                        r['created_at'] as String,
                      ).isAfter(flowStart.subtract(const Duration(seconds: 5))),
                )
                .map((r) => r['_id'] as String),
          );
        } on DioException {
          // Documented: if recovery fails, an ambiguous reservation may remain
          // until it expires; do not cancel anything else.
        }
      }
      for (final id in cleanupIds) {
        await cancelReservation(api, setupToken, id);
      }
      await cancelReservation(api, setupToken, oldId);
      await clearTestToken();
    }
  });
}
