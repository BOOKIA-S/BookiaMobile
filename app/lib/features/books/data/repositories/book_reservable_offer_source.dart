import 'package:bookia_mobile/core/offers/reservable_offer.dart';
import 'package:bookia_mobile/features/books/domain/repositories/book_repository.dart';

/// Adapter of the shared offer contract over the existing books repository
/// (no second HTTP client and no duplicated DTO logic).
class BookReservableOfferSource implements ReservableOfferSource {
  const BookReservableOfferSource(this._books);

  final BookRepository _books;

  @override
  Future<ReservableOffer?> find({
    required String bookId,
    required String offerId,
  }) async {
    final book = await _books.getById(bookId);
    for (final offer in book.offers) {
      if (offer.id != offerId) continue;
      return ReservableOffer(
        bookId: book.id,
        bookTitle: book.title,
        bookAuthor: book.author,
        offerId: offer.id,
        storeName: offer.store.name,
        storeAddress: offer.store.address,
        price: offer.price,
        stock: offer.stock,
      );
    }
    return null;
  }
}
