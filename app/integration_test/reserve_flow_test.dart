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
/// emulator with `api-ci` running:
///
/// flutter test integration_test/reserve_flow_test.dart -d emulator-5554 \
///   --dart-define=API_BASE_URL=http://10.0.2.2:4000/api \
///   --dart-define=BOOKIA_TEST_EMAIL=... \
///   --dart-define=BOOKIA_TEST_PASSWORD=...
///
/// It starts on screen 07 because the search result -> book detail navigation
/// belongs to I2 and is still pending; the rest of the flow is the I5 segment.
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

/// Logs in the test reader, registering it the first time.
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

/// First offer with at least two copies, so the quantity can be increased.
Map<String, dynamic> _availableOffer(Map<String, dynamic> books) {
  for (final book in books['items'] as List<dynamic>) {
    final b = book as Map<String, dynamic>;
    for (final offer in b['offers'] as List<dynamic>) {
      final o = offer as Map<String, dynamic>;
      if ((o['stock'] as num) >= 2) return {'book': b, 'offer': o};
    }
  }
  fail('No offer with at least two copies; run the seed first.');
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

Future<void> _cancelWith(String token, String reservationId) async {
  await _client().patch<void>(
    '/reservations/$reservationId/cancel',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
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

  testWidgets('guest signs in, reserves and gets the QR of the server id', (
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
    const quantity = 2;

    String? reservationId;
    try {
      await const TokenStorage().clearToken();
      await _installApp(tester, book['_id'] as String);

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
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Confirmar reserva'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar reserva'));

      await _pumpUntil(tester, find.byType(PickupQr));
      expect(find.text('¡Libro apartado!'), findsOneWidget);

      final token = await const TokenStorage().readToken();
      expect(token, isNotNull);
      final mine = (await _client().get<Map<String, dynamic>>(
        '/reservations/mine',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      )).data!;
      final created = (mine['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (r) => r['status'] == 'pendiente' && r['offer_id'] == offer['_id'],
          );
      reservationId = created['_id'] as String;

      expect(
        tester.widget<PickupQr>(find.byType(PickupQr)).data,
        reservationId,
      );
      expect(
        find.text(
          'BK-${reservationId.substring(reservationId.length - 4).toUpperCase()}',
        ),
        findsOneWidget,
      );
      expect(created['quantity'], quantity);
      expect(
        find.text(
          '\$${((offer['price'] as num) * quantity).toStringAsFixed(2)}',
        ),
        findsOneWidget,
      );
    } finally {
      if (reservationId != null) {
        await _cancelWith(setupToken, reservationId);
      }
    }
  });

  testWidgets('an existing reservation opens screen 11 from /mine', (
    tester,
  ) async {
    final api = _client();
    final setupToken = await _token(api);
    final books = (await api.get<Map<String, dynamic>>(
      '/books',
      queryParameters: {'limit': 100},
    )).data!;
    final offer = _availableOffer(books)['offer'] as Map<String, dynamic>;
    final created = (await api.post<Map<String, dynamic>>(
      '/reservations',
      data: {'offer_id': offer['_id'], 'quantity': 1},
      options: Options(headers: {'Authorization': 'Bearer $setupToken'}),
    )).data!;
    final reservationId = created['_id'] as String;

    try {
      await const TokenStorage().saveToken(setupToken);
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
              initialLocation: '/reservation/$reservationId',
            ),
          ),
        ),
      );
      await _pumpUntil(tester, find.byType(PickupQr));

      expect(find.text('¡Libro apartado!'), findsOneWidget);
      expect(
        tester.widget<PickupQr>(find.byType(PickupQr)).data,
        reservationId,
      );
    } finally {
      await _cancelWith(setupToken, reservationId);
      await const TokenStorage().clearToken();
    }
  });
}
