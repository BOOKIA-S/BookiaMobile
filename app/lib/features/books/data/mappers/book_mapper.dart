import 'package:bookia_mobile/features/books/data/dto/book_dto.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';

/// Adapter (PAT-07): API DTO to domain entity. Empty strings become null.
extension BookMapper on BookDto {
  Book toEntity() => Book(
    id: id,
    title: title,
    author: author,
    genre: _orNull(genre),
    publisher: _orNull(publisher),
    edition: _orNull(edition),
    isbn: _orNull(isbn),
    offers: [for (final o in offers) o.toEntity()],
  );
}

extension OfferMapper on OfferDto {
  BookOffer toEntity() => BookOffer(
    id: id,
    price: price,
    stock: stock,
    store: OfferStore(
      id: store.id,
      name: store.name,
      address: _orNull(store.address),
    ),
  );
}

String? _orNull(String? value) =>
    value == null || value.trim().isEmpty ? null : value;
