import 'package:bookia_mobile/core/offers/reservable_offer.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/domain/repositories/book_repository.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';
import 'package:bookia_mobile/features/reservations/domain/repositories/reservation_repository.dart';

/// Offer returned by the shared contract for screen 10.
ReservableOffer testOffer({int stock = 6, double price = 129}) =>
    ReservableOffer(
      bookId: 'b1',
      bookTitle: 'Aura',
      bookAuthor: 'Carlos Fuentes',
      offerId: 'o1',
      storeName: 'Librería del Centro',
      storeAddress: 'Calle Juárez 10',
      price: price,
      stock: stock,
    );

/// Book with one offer of [stock] copies at [price] (screen 07).
Book testBook({int stock = 6, double price = 129}) => Book(
  id: 'b1',
  title: 'Aura',
  author: 'Carlos Fuentes',
  offers: [
    BookOffer(
      id: 'o1',
      price: price,
      stock: stock,
      store: const OfferStore(
        id: 's1',
        name: 'Librería del Centro',
        address: 'Calle Juárez 10',
      ),
    ),
  ],
);

Reservation testReservation({
  String id = 'r1',
  String offerId = 'o1',
  double price = 129,
  int quantity = 1,
  ReservationStatus status = const Pending(),
  DateTime? createdAt,
  DateTime? expiresAt,
  ReservationBook? book,
  ReservationStore? store,
}) => Reservation(
  id: id,
  userId: 'u1',
  offerId: offerId,
  storeId: 's1',
  bookId: 'b1',
  price: price,
  quantity: quantity,
  status: status,
  expiresAt: expiresAt ?? DateTime.utc(2026, 11, 19, 20),
  createdAt: createdAt ?? DateTime.utc(2026, 11, 17, 20),
  book: book,
  store: store,
);

class FakeReservableOfferSource implements ReservableOfferSource {
  FakeReservableOfferSource({ReservableOffer? offer, this.missing = false})
    : offer = offer ?? testOffer();

  final ReservableOffer offer;
  final bool missing;
  int calls = 0;

  @override
  Future<ReservableOffer?> find({
    required String bookId,
    required String offerId,
  }) async {
    calls++;
    return missing ? null : offer;
  }
}

class FakeBookRepository implements BookRepository {
  FakeBookRepository([Book? book]) : book = book ?? testBook();

  final Book book;
  int calls = 0;

  @override
  Future<Book> getById(String id) async {
    calls++;
    return book;
  }

  @override
  Future<Book?> findByIsbn(String isbn) async => null;
}

class FakeReservationRepository implements ReservationRepository {
  int createCalls = 0;
  int listCalls = 0;
  String? lastOfferId;
  int? lastQuantity;
  Future<Reservation> Function(String offerId, int quantity)? onCreate;
  Future<List<Reservation>> Function()? onList;

  @override
  Future<Reservation> create({required String offerId, required int quantity}) {
    createCalls++;
    lastOfferId = offerId;
    lastQuantity = quantity;
    return onCreate?.call(offerId, quantity) ??
        Future.value(testReservation(quantity: quantity));
  }

  @override
  Future<List<Reservation>> listMine() {
    listCalls++;
    return onList?.call() ?? Future.value([testReservation()]);
  }
}
