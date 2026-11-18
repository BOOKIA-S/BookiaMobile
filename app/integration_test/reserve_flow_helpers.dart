import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared setup for the I5 integration tests. This file is not a test itself.
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
const testEmail = String.fromEnvironment('BOOKIA_TEST_EMAIL');
const testPassword = String.fromEnvironment('BOOKIA_TEST_PASSWORD');

void requireIntegrationConfig() {
  if (apiBaseUrl.isEmpty || testEmail.isEmpty || testPassword.isEmpty) {
    fail(
      'Pass API_BASE_URL, BOOKIA_TEST_EMAIL and BOOKIA_TEST_PASSWORD with '
      '--dart-define.',
    );
  }
}

Dio integrationClient() => Dio(
  BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ),
);

Future<void> pumpUntil(
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

Future<String> integrationToken(Dio api) async {
  try {
    final response = await api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': testEmail, 'password': testPassword, 'client': 'mobile'},
    );
    return response.data!['token'] as String;
  } on DioException catch (error) {
    if (error.response?.statusCode != 401) rethrow;
    final response = await api.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': 'I5 Integration Reader',
        'email': testEmail,
        'password': testPassword,
        'client': 'mobile',
      },
    );
    return response.data!['token'] as String;
  }
}

Map<String, dynamic> availableOffer(Map<String, dynamic> books) {
  for (final book in books['items'] as List<dynamic>) {
    final b = book as Map<String, dynamic>;
    for (final offer in b['offers'] as List<dynamic>) {
      final o = offer as Map<String, dynamic>;
      if ((o['stock'] as num) >= 4) return {'book': b, 'offer': o};
    }
  }
  fail('No offer with at least four copies; run the seed first.');
}

Future<List<Map<String, dynamic>>> myReservations(Dio api, String token) async {
  final response = await api.get<Map<String, dynamic>>(
    '/reservations/mine',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return (response.data!['items'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
}

Set<String> reservationIds(List<Map<String, dynamic>> items) => {
  for (final item in items) item['_id'] as String,
};

Future<Map<String, dynamic>> createReservation(
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

Future<void> cancelReservation(Dio api, String token, String id) async {
  await api.patch<void>(
    '/reservations/$id/cancel',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
}

Future<void> installApp(WidgetTester tester, String bookId) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiBaseUrlProvider.overrideWithValue(apiBaseUrl)],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: createRouter(initialLocation: '/books/$bookId'),
      ),
    ),
  );
  await pumpUntil(tester, find.widgetWithText(TextButton, 'Reservar'));
}

Future<void> loginAndReserve(
  WidgetTester tester, {
  required int quantity,
}) async {
  await tester.tap(find.widgetWithText(TextButton, 'Reservar').first);
  await pumpUntil(
    tester,
    find.widgetWithText(TextFormField, 'Correo electrónico'),
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Correo electrónico'),
    testEmail,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Contraseña'),
    testPassword,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));

  await pumpUntil(tester, find.text('Cantidad'));
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
  await pumpUntil(tester, find.text('¡Libro apartado!'));
}

Future<void> clearTestToken() => const TokenStorage().clearToken();
