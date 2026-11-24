import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/presentation/controllers/search_results_controller.dart';
import 'package:bookia_mobile/features/search/presentation/widgets/book_result_tile.dart';
import 'package:bookia_mobile/features/search/presentation/widgets/filters_sheet.dart';
import 'package:bookia_mobile/features/search/presentation/widgets/offline_banner.dart';
import 'package:bookia_mobile/features/search/presentation/widgets/quick_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen 04 Resultados: paginated list (20 per page, infinite scroll).
class SearchResultsPage extends ConsumerWidget {
  const SearchResultsPage({required this.query, super.key});

  final SearchQuery query;

  Future<void> _openFilters(BuildContext context) async {
    final filters = await showFiltersSheet(context, query);
    if (filters == null || !context.mounted) return;
    _apply(context, filters);
  }

  void _apply(BuildContext context, SearchFilters filters) {
    final params = searchQueryParams((q: query.q, filters: filters));
    context.go(Uri(path: AppRoutes.search, queryParameters: params).toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = searchResultsProvider(query);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(query.filters.genre ?? query.q ?? 'Resultados'),
        actions: [
          IconButton(
            tooltip: 'Filtros',
            onPressed: () => _openFilters(context),
            icon: Badge(
              isLabelVisible: query.filters.activeCount > 0,
              label: Text('${query.filters.activeCount}'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
        bottom: QuickChips(
          filters: query.filters,
          onChanged: (f) => _apply(context, f),
        ),
      ),
      body: ref
          .watch(provider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _Message(
              e is Failure ? e.message : 'No pudimos buscar.',
              action: TextButton(
                onPressed: () => ref.invalidate(provider),
                child: const Text('Reintentar'),
              ),
            ),
            data: (r) => r.items.isEmpty
                ? const _Message(
                    'No encontramos libros. Prueba escanear el ISBN de la '
                    'contraportada.',
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.extentAfter < 300) {
                        ref.read(provider.notifier).loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: r.visible.length + 2,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          final found = r.total == 1
                              ? 'libro encontrado'
                              : 'libros encontrados';
                          final count = Text(
                            r.onlyAvailable
                                ? '${r.total} $found · solo disponibles'
                                : '${r.total} $found',
                            style: text.titleSmall,
                          );
                          final saved = r.savedAt;
                          if (saved == null) return count;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OfflineBanner(
                                savedAt: saved,
                                onRetry: () => ref.invalidate(provider),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              count,
                            ],
                          );
                        }
                        if (i > r.visible.length) return _footer(ref, r);
                        final book = r.visible[i - 1];
                        return BookResultTile(
                          book: book,
                          onTap: () =>
                              context.push<void>(AppRoutes.book(book.id)),
                        );
                      },
                    ),
                  ),
          ),
    );
  }

  /// Loader while a page arrives; "Cargar más" when hidden sold-out rows
  /// leave too little to scroll.
  Widget _footer(WidgetRef ref, SearchResults r) {
    if (r.loadingMore) return const Center(child: CircularProgressIndicator());
    if (!r.hasMore) return const SizedBox.shrink();
    return Center(
      child: TextButton(
        onPressed: ref.read(searchResultsProvider(query).notifier).loadMore,
        child: const Text('Cargar más'),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    ),
  );
}
