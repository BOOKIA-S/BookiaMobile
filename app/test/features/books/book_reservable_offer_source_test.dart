import 'package:bookia_mobile/features/books/data/repositories/book_reservable_offer_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../reservations/reservation_test_helpers.dart';

void main() {
  test('adapts the book repository offer to the shared contract', () async {
    final source = BookReservableOfferSource(FakeBookRepository());

    final offer = await source.find(bookId: 'b1', offerId: 'o1');

    expect(offer, isNotNull);
    expect(offer!.bookId, 'b1');
    expect(offer.bookTitle, 'Aura');
    expect(offer.bookAuthor, 'Carlos Fuentes');
    expect(offer.offerId, 'o1');
    expect(offer.storeName, 'Librería del Centro');
    expect(offer.storeAddress, 'Calle Juárez 10');
    expect(offer.price, 129);
    expect(offer.stock, 6);
    expect(offer.isAvailable, isTrue);
  });

  test('returns null when the offer is not part of the book', () async {
    final source = BookReservableOfferSource(FakeBookRepository());

    expect(await source.find(bookId: 'b1', offerId: 'gone'), isNull);
  });

  test('a sold-out offer is still returned with its stock', () async {
    final source = BookReservableOfferSource(
      FakeBookRepository(testBook(stock: 0)),
    );

    final offer = await source.find(bookId: 'b1', offerId: 'o1');

    expect(offer!.stock, 0);
    expect(offer.isAvailable, isFalse);
  });
}
