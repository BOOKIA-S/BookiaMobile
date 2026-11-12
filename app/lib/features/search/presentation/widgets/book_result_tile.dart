import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _mxn = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

/// A result row: title, author, publisher, "desde $X", stores and copies.
class BookResultTile extends StatelessWidget {
  const BookResultTile({required this.book, super.key});

  final BookSummary book;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final price = book.minPrice;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.title, style: text.titleMedium),
            Text('${book.author} · ${book.publisher}', style: text.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    price == null
                        ? 'Sin precio'
                        : 'desde ${_mxn.format(price)}',
                    style: text.titleSmall,
                  ),
                ),
                AvailabilityBadge(book: book),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge({required this.book, super.key});

  final BookSummary book;

  @override
  Widget build(BuildContext context) {
    final stores = book.storeCount == 1 ? 'librería' : 'librerías';
    final (label, fg, bg) = switch (book.availability) {
      Availability.available => (
        'En ${book.storeCount} $stores · ${book.totalStock} piezas',
        AppColors.success,
        AppColors.successContainer,
      ),
      Availability.low => (
        'Últimas ${book.totalStock} · ${book.storeCount} $stores',
        AppColors.warning,
        AppColors.warningContainer,
      ),
      Availability.soldOut => (
        'Agotado',
        AppColors.textSecondary,
        AppColors.sand,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12)),
    );
  }
}
