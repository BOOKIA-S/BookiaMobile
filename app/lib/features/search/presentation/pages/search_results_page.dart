import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/search/presentation/controllers/search_results_controller.dart';
import 'package:bookia_mobile/features/search/presentation/widgets/book_result_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen 04 Resultados: paginated list (20 per page, infinite scroll).
class SearchResultsPage extends ConsumerWidget {
  const SearchResultsPage({required this.query, super.key});

  final SearchQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = searchResultsProvider(query);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(query.genre ?? query.q ?? 'Resultados')),
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
                      itemCount: r.items.length + 2,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          final noun = r.total == 1 ? 'libro' : 'libros';
                          return Text(
                            '${r.total} $noun encontrados',
                            style: text.titleSmall,
                          );
                        }
                        if (i > r.items.length) {
                          return r.loadingMore
                              ? const Center(child: CircularProgressIndicator())
                              : const SizedBox.shrink();
                        }
                        return BookResultTile(book: r.items[i - 1]);
                      },
                    ),
                  ),
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
