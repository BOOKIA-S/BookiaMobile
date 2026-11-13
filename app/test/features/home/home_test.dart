import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/home/data/repositories/home_repository_impl.dart';
import 'package:bookia_mobile/features/home/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  test('repository reads genres from /books/filters', () async {
    final api = _MockApiClient();
    when(() => api.get<Map<String, dynamic>>('/books/filters')).thenAnswer(
      (_) async => {
        'genres': ['Novela', 'Poesía'],
        'publishers': ['Alfaguara'],
      },
    );
    expect(await HomeRepositoryImpl(api).getGenres(), ['Novela', 'Poesía']);
  });

  Future<GoRouter> pumpHome(
    WidgetTester tester,
    MockHomeRepository repo,
  ) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...offlineOverrides().skip(1),
          homeRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    return router;
  }

  testWidgets('shows a loader, then the genre chips', (tester) async {
    final repo = MockHomeRepository();
    when(repo.getGenres).thenAnswer((_) async => ['Novela', 'Poesía']);
    await pumpHome(tester, repo);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'Poesía'), findsOneWidget);
  });

  testWidgets('shows the empty state', (tester) async {
    final repo = MockHomeRepository();
    when(repo.getGenres).thenAnswer((_) async => []);
    await pumpHome(tester, repo);
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay géneros.'), findsOneWidget);
  });

  testWidgets('shows the error and retries', (tester) async {
    final repo = MockHomeRepository();
    when(repo.getGenres).thenThrow(const NetworkFailure());
    await pumpHome(tester, repo);
    await tester.pumpAndSettle();
    expect(find.text(const NetworkFailure().message), findsOneWidget);

    when(repo.getGenres).thenAnswer((_) async => ['Novela']);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'Novela'), findsOneWidget);
  });

  testWidgets('search and genre chips open results', (tester) async {
    final repo = MockHomeRepository();
    when(repo.getGenres).thenAnswer((_) async => ['Novela']);
    final router = await pumpHome(tester, repo);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Rulfo');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/search?q=Rulfo');

    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novela'));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/search?genre=Novela');
  });
}
