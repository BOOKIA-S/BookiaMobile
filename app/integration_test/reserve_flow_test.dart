import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/storage/token_storage.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/pickup_code_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end segment of I5 against the real API (PRU-03), on a device or
/// emulator with the local API running:
///
/// flutter test integration_test/reserve_flow_test.dart -d emulator-5554 \
///   --dart-define=API_BASE_URL=http://10.0.2.2:4000/api \
///   --dart-define=BOOKIA_TEST_EMAIL=... \
///   --dart-define=BOOKIA_TEST_PASSWORD=...
///
/// The dedicated test account must not be used by another device during the
/// run. Cleanup only touches reservations created by this run (ids absent
/// before the flow and created after its start); pre-existing reservations
/// are never cancelled.
const _baseUrl = String.fromEnvironment('API_BASE_URL');
const _email = String.fromEnvironment('BOOKIA_TEST_EMAIL');
const _password = String.fromEnvironment('BOOKIA_TEST_PASSWORD');

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

Dio _client() => Dio(
  BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ),
);

Future<String> _token(Dio api) async {
  try {
    final response = await api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': _email, 'password': _password, 'client': 'mobile'},
    );
    return response.data!['token'] as String;
  } on DioException catch (error) {
    if (error.response?.statusCode != 401) rethrow;
    final response = await api.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': 'I5 Integration Reader',
        'email': _email,
        'password': _password,
        'client': 'mobile',
      },
    );
    return response.data!['token'] as String;
  }
}

Map<String, dynamic> _availableOffer(Map<String, dynamic> books) {
  for (final book in books['items'] as List<dynamic>) {
    final b = book as Map<String, dynamic>;
    for (final offer in b['offers'] as List<dynamic>) {
      final o = offer as Map<String, dynamic>;
      if ((o['stock'] as num) >= 4) return {'book': b, 'offer': o};
    }
  }
  fail('No offer with at least four copies; run the seed first.');
}

Future<List<Map<String, dynamic>>> _mine(Dio api, String token) async {
  final response = await api.get<Map<String, dynamic>>(
    '/reservations/mine',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return (response.data!['items'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
}

Set<String> _ids(List<Map<String, dynamic>> items) => {
  for (final item in items) item['_id'] as String,
};

Future<Map<String, dynamic>> _create(
  Dio api,
  String token,
  String offerId,
  int quantity,
) async {
  final response = await api.post<Map<String, dynamic>>(
    '/reservations',
    data: {'offer_id': offerId, 'quantity': quantity},
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return response.data!;
}

Future<void> _cancel(Dio api, String token, String id) async {
  await api.patch<void>(
    '/reservations/$id/cancel',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
}

Future<void> _installApp(WidgetTester tester, String bookId) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiBaseUrlProvider.overrideWithValue(_baseUrl)],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: createRouter(initialLocation: '/books/$bookId'),
      ),
    ),
  );
  await _pumpUntil(tester, find.widgetWithText(TextButton, 'Reservar'));
}

Future<void> _loginAndReserve(
  WidgetTester tester, {
  required int quantity,
}) async {
  await tester.tap(find.widgetWithText(TextButton, 'Reservar').first);
  await _pumpUntil(
    tester,
    find.widgetWithText(TextFormField, 'Correo electrónico'),
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Correo electrónico'),
    _email,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Contraseña'),
    _password,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));

  await _pumpUntil(tester, find.text('Cantidad'));
  for (var i = 1; i < quantity; i++) {
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.scrollUntilVisible(
    find.widgetWithText(FilledButton, 'Confirmar reserva'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Confirmar reserva'));
  await _pumpUntil(tester, find.text('¡Libro apartado!'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (_baseUrl.isEmpty || _email.isEmpty || _password.isEmpty) {
      fail(
        'Pass API_BASE_URL, BOOKIA_TEST_EMAIL and BOOKIA_TEST_PASSWORD with '
        '--dart-define.',
      );
    }
  });

  testWidgets('guest reserves and the new reservation is distinguishable', (
    tester,
  ) async {
    final api = _client();
    final setupToken = await _token(api);
    final books = (await api.get<Map<String, dynamic>>(
      '/books',
      queryParameters: {'limit': 100},
    )).data!;
    final pick = _availableOffer(books);
    final book = pick['book'] as Map<String, dynamic>;
    final offer = pick['offer'] as Map<String, dynamic>;
    final offerId = offer['_id'] as String;
    final price = (offer['price'] as num).toDouble();
    final initialStock = (offer['stock'] as num).toInt();
    const quantity = 2;

    // A previous active reservation of the same offer must never be mistaken
    // for the one created by the flow.
    final old = await _create(api, setupToken, offerId, 1);
    final oldId = old['_id'] as String;
    final beforeFlowIds = _ids(await _mine(api, setupToken));
    final flowStart = DateTime.now().toUtc();
    String? newId;

    try {
      await const TokenStorage().clearToken();
      await _installApp(tester, book['_id'] as String);
      await _loginAndReserve(tester, quantity: quantity);

      final token = await const TokenStorage().readToken();
      expect(token, isNotNull);
      final mine = await _mine(api, token!);
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
          final mine = await _mine(api, setupToken);
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
        await _cancel(api, setupToken, id);
      }
      await _cancel(api, setupToken, oldId);
      await const TokenStorage().clearToken();
    }
  });

  testWidgets('an existing reservation opens screen 11 without new POSTs', (
    tester,
  ) async {
    final api = _client();
    final setupToken = await _token(api);
    final books = (await api.get<Map<String, dynamic>>(
      '/books',
      queryParameters: {'limit': 100},
    )).data!;
    final offer = _availableOffer(books)['offer'] as Map<String, dynamic>;
    final created = await _create(api, setupToken, offer['_id'] as String, 1);
    final reservationId = created['_id'] as String;

    try {
      await const TokenStorage().saveToken(setupToken);
      final mine = await _mine(api, setupToken);
      final reservation = mine.firstWhere((r) => r['_id'] == reservationId);
      final container = ProviderContainer(
        overrides: [apiBaseUrlProvider.overrideWithValue(_baseUrl)],
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
      await _pumpUntil(tester, find.byType(PickupQr));

      expect(find.text('Reserva encontrada'), findsOneWidget);
      expect(find.text('¡Libro apartado!'), findsNothing);
      expect(
        tester.widget<PickupQr>(find.byType(PickupQr)).data,
        reservationId,
      );
      expect(find.text(reservation['book']['title'] as String), findsOneWidget);
    } finally {
      await _cancel(api, setupToken, reservationId);
      await const TokenStorage().clearToken();
    }
  });
}
