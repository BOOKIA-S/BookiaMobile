import 'package:bookia_mobile/features/search/data/dto/book_summary_dto.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';

/// Adapter (PAT-07): API DTO to domain entity.
extension BookSummaryMapper on BookSummaryDto {
  BookSummary toEntity() => BookSummary(
    id: id,
    title: title,
    author: author,
    publisher: publisher,
    minPrice: minPrice,
    totalStock: totalStock,
    storeCount: availableOffers,
  );
}
