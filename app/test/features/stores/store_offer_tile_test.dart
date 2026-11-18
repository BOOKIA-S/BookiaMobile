import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/presentation/widgets/store_offer_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StoreOffer offer({int stock = 6, bool? available, double price = 75}) =>
    StoreOffer(
      id: 'o1',
      bookId: 'b1',
      title: 'Cien años de soledad',
      author: 'Gabriel García Márquez',
      price: price,
      stock: stock,
      isAvailable: available ?? stock > 0,
    );

void main() {
  Future<void> pump(WidgetTester tester, StoreOffer o) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: StoreOfferTile(offer: o)),
    ),
  );

  testWidgets('shows the title, the author and the price', (tester) async {
    await pump(tester, offer(price: 1234.5));

    expect(find.text('Cien años de soledad'), findsOneWidget);
    expect(find.text('Gabriel García Márquez'), findsOneWidget);
    expect(find.text(r'$1,234.50'), findsOneWidget);
  });

  group('StockBadge', () {
    Future<void> badge(WidgetTester tester, StoreOffer o) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StockBadge(offer: o)),
      ),
    );

    testWidgets('three or more copies are "disponibles"', (tester) async {
      await badge(tester, offer(stock: 3));

      expect(find.text('3 disponibles'), findsOneWidget);
    });

    testWidgets('two copies or fewer are "Últimas"', (tester) async {
      await badge(tester, offer(stock: 2));
      expect(find.text('Últimas 2'), findsOneWidget);

      await badge(tester, offer(stock: 1));
      expect(find.text('Últimas 1'), findsOneWidget);
    });

    testWidgets('without copies the offer is "Agotado"', (tester) async {
      await badge(tester, offer(stock: 0));

      expect(find.text('Agotado'), findsOneWidget);
    });

    testWidgets('an unavailable offer is "Agotado" whatever its stock', (
      tester,
    ) async {
      await badge(tester, offer(stock: 5, available: false));

      expect(find.text('Agotado'), findsOneWidget);
      expect(find.text('5 disponibles'), findsNothing);
    });
  });
}
