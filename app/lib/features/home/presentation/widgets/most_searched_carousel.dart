import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/home/presentation/controllers/most_searched_controller.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final _mxn = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

/// "Más buscados" of screen 03: a horizontal carousel with "desde $X".
class MostSearchedCarousel extends ConsumerWidget {
  const MostSearchedCarousel({super.key});

  static const height = 132.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return ref
        .watch(mostSearchedProvider)
        .when(
          loading: () => const SizedBox(
            height: height,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Row(
            children: [
              Expanded(
                child: Text(
                  e is Failure ? e.message : 'No pudimos cargar los libros.',
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(mostSearchedProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
          data: (m) => m.books.isEmpty
              ? Text('Aún no hay libros.', style: text.bodyMedium)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.fromHistory
                          ? 'Según tus búsquedas en este teléfono'
                          : 'Del catálogo de BOOKIA',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: height,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: m.books.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (_, i) => _BookCard(book: m.books[i]),
                      ),
                    ),
                  ],
                ),
        );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final BookSummary book;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final price = book.minPrice;
    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push<void>(AppRoutes.book(book.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: text.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  book.author,
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  price == null ? 'Agotado' : 'desde ${_mxn.format(price)}',
                  style: text.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
