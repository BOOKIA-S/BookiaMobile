import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/domain/repositories/book_repository.dart';
import 'package:bookia_mobile/features/books/presentation/pages/book_detail_page.dart';
import 'package:bookia_mobile/features/books/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class MockBookRepository extends Mock implements BookRepository {}

BookOffer offer(String store, double price, int stock) => BookOffer(
  id: 'o-$store',
  price: price,
  stock: stock,
  store: OfferStore(id: store, name: store, address: 'Calle $store'),
);

const book = Book(id: 'b1', title: 'Pedro Páramo', author: 'Juan Rulfo');

void main() {
  late MockBookRepository repo;
  setUp(() => repo = MockBookRepository());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bookRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: BookDetailPage(bookId: 'b1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('compares stores: in stock first, cheapest marked', (
    tester,
  ) async {
    when(() => repo.getById('b1')).thenAnswer(
      (_) async => Book(
        id: 'b1',
        title: 'Pedro Páramo',
        author: 'Juan Rulfo',
        publisher: 'RM',
        isbn: '9786071612345',
        offers: [
          offer('Centro', 120, 6),
          offer('Rincón', 60, 0),
          offer('Sol', 95.5, 2),
        ],
      ),
    );
    await pump(tester);

    expect(find.text('Pedro Páramo'), findsOneWidget);
    expect(find.text('ISBN 9786071612345'), findsOneWidget);
    expect(find.text(r'En 2 librerías · desde $95.50'), findsOneWidget);
    final sol = tester.getTopLeft(find.text('Sol')).dy;
    final centro = tester.getTopLeft(find.text('Centro')).dy;
    final rincon = tester.getTopLeft(find.text('Rincón')).dy;
    expect(sol < centro && centro < rincon, isTrue);
    expect(find.text('Mejor precio'), findsOneWidget);
    expect(find.text('6 disponibles'), findsOneWidget);
    expect(find.text('Últimas 2'), findsOneWidget);
    expect(find.text('Agotado'), findsOneWidget);
  });

  testWidgets('a book no store has shows an empty state', (tester) async {
    when(() => repo.getById('b1')).thenAnswer((_) async => book);
    await pump(tester);
    expect(find.text('Agotado en todas las librerías'), findsOneWidget);
    expect(
      find.text('Por ahora ninguna librería de Huauchinango lo tiene.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the failure and retries', (tester) async {
    when(() => repo.getById('b1'))
        .thenAnswer((_) => Future.error(const NetworkFailure()));
    await pump(tester);
    expect(find.text(const NetworkFailure().message), findsOneWidget);

    when(() => repo.getById('b1')).thenAnswer((_) async => book);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Pedro Páramo'), findsOneWidget);
  });

  testWidgets('route /books/:id opens screen 07', (tester) async {
    when(() => repo.getById('b1')).thenAnswer((_) async => book);
    final router = createRouter(initialLocation: AppRoutes.book('b1'));
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...offlineOverrides(),
          bookRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Ficha de libro'), findsOneWidget);
  });
}
