import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/presentation/controllers/book_detail_controller.dart';
import 'package:bookia_mobile/features/books/presentation/widgets/offer_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen 07 Ficha de libro: the book and every store that sells it,
/// from the cheapest to the most expensive.
class BookDetailPage extends ConsumerWidget {
  const BookDetailPage({required this.bookId, super.key});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = bookDetailProvider(bookId);
    return Scaffold(
      appBar: AppBar(title: const Text('Ficha de libro')),
      body: ref
          .watch(provider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e is Failure ? e.message : 'No pudimos cargar el libro.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(provider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
            data: (book) => _BookDetail(book: book),
          ),
    );
  }
}

class _BookDetail extends StatelessWidget {
  const _BookDetail({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final offers = book.offersByPrice;
    final details = [book.publisher, book.genre, book.edition].nonNulls;
    final minPrice = book.minPrice;
    final stores = offers.where((o) => o.isAvailable).length;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(book.title, style: text.headlineSmall),
        Text(book.author, style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (details.isNotEmpty)
          Text(details.join(' · '), style: text.bodySmall),
        if (book.isbn != null) Text('ISBN ${book.isbn}', style: text.bodySmall),
        const SizedBox(height: AppSpacing.xl),
        Text('Dónde comprarlo', style: text.titleMedium),
        Text(
          minPrice == null
              ? 'Agotado en todas las librerías'
              : 'En $stores ${stores == 1 ? 'librería' : 'librerías'} · '
                    'desde ${mxn.format(minPrice)}',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (offers.isEmpty)
          const Text('Por ahora ninguna librería de Huauchinango lo tiene.'),
        for (final offer in offers)
          OfferTile(
            offer: offer,
            isBestPrice: offer.isAvailable && offer.price == minPrice,
          ),
      ],
    );
  }
}
