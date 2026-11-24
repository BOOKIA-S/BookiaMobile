import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/search/presentation/widgets/book_result_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

import 'reserve_flow_helpers.dart'
    show apiBaseUrl, integrationClient, pumpUntil;

final _mxn = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

/// PRU-03: search → book → store against the real API (seeded). Needs only
/// `--dart-define=API_BASE_URL=...`; it signs in nobody and writes nothing.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (apiBaseUrl.isEmpty) fail('Pass API_BASE_URL with --dart-define.');
  });

  testWidgets('a reader searches a book, compares stores and opens one', (
    tester,
  ) async {
    // Pick a seeded book with stock and its cheapest store from the API.
    final books = (await integrationClient().get<Map<String, dynamic>>(
      '/books',
      queryParameters: {'limit': 100},
    )).data!;
    final book = (books['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (b) => (b['total_stock'] as num) > 0,
          orElse: () => fail('No book with stock; run the seed first.'),
        );
    final title = book['title'] as String;
    final offers =
        (book['offers'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .where((o) => o['is_available'] == true)
            .toList()
          ..sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    final cheapest = offers.first;
    final store = cheapest['store'] as Map<String, dynamic>;
    final storeName = store['name'] as String;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiBaseUrlProvider.overrideWithValue(apiBaseUrl)],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: createRouter(),
        ),
      ),
    );
    await pumpUntil(tester, find.text('¿Qué libro buscas hoy?'));

    // 03 → 04: search by title.
    await tester.enterText(find.byType(TextField).first, title);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    final row = find.widgetWithText(BookResultTile, title);
    await pumpUntil(tester, row);
    expect(find.textContaining('encontrado'), findsOneWidget);
    expect(
      find.descendant(
        of: row.first,
        matching: find.text('desde ${_mxn.format(cheapest['price'])}'),
      ),
      findsOneWidget,
    );

    // 04 → 07: the book detail compares the stores that have it.
    await tester.tap(row.first);
    await pumpUntil(tester, find.text('Dónde comprarlo'));
    expect(find.text(title), findsWidgets);
    await tester.scrollUntilVisible(
      find.text(storeName),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mejor precio'), findsOneWidget);

    // Back on 03 the search feeds "Búsquedas recientes" and "Más buscados".
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inicio'));
    await pumpUntil(tester, find.text('Según tus búsquedas en este teléfono'));
    expect(find.widgetWithText(ActionChip, title), findsOneWidget);

    // 03 → 08 → 09: the store lists the book in its catalog.
    final allStores = find.text('Ver todas las librerías');
    await tester.scrollUntilVisible(
      allStores,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Lift the button above the bottom bar before tapping it.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(allStores);
    await pumpUntil(tester, find.text(storeName));
    await tester.tap(find.text(storeName).first);
    await pumpUntil(tester, find.textContaining('Catálogo ('));
    await tester.scrollUntilVisible(
      find.text(title),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(title), findsOneWidget);
  });
}
