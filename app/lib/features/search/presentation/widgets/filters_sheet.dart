import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:bookia_mobile/features/search/presentation/search_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens screen 05 over 04. Returns the chosen filters, or null if dismissed.
Future<SearchFilters?> showFiltersSheet(
  BuildContext context,
  SearchQuery query,
) => showModalBottomSheet<SearchFilters>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => FiltersSheet(query: query),
);

/// Screen 05 Filtros: genre, store, price $50–$300 and "Solo disponibles".
class FiltersSheet extends ConsumerStatefulWidget {
  const FiltersSheet({required this.query, super.key});

  final SearchQuery query;

  @override
  ConsumerState<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<FiltersSheet> {
  static const _full = RangeValues(
    SearchFilters.priceFloor,
    SearchFilters.priceCeiling,
  );

  late String? _genre = widget.query.filters.genre;
  late String? _storeId = widget.query.filters.storeId;
  late RangeValues _price = RangeValues(
    widget.query.filters.minPrice ?? _full.start,
    widget.query.filters.maxPrice ?? _full.end,
  );
  late bool _onlyAvailable = widget.query.filters.onlyAvailable;

  /// The draft; a range at its limits sends no price filter.
  SearchFilters get _draft => SearchFilters(
    genre: _genre,
    storeId: _storeId,
    minPrice: _price.start > _full.start ? _price.start : null,
    maxPrice: _price.end < _full.end ? _price.end : null,
    onlyAvailable: _onlyAvailable,
  );

  void _clear() => setState(() {
    _genre = null;
    _storeId = null;
    _price = _full;
    _onlyAvailable = false;
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final options = ref.watch(filterOptionsProvider);
    final count = ref.watch(
      resultCountProvider((q: widget.query.q, filters: _draft)),
    );
    final label = count.whenOrNull(
      data: (n) => 'Ver $n ${n == 1 ? 'resultado' : 'resultados'}',
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtros', style: text.titleLarge),
            const SizedBox(height: AppSpacing.md),
            options.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Column(
                children: [
                  Text(
                    e is Failure ? e.message : 'No pudimos cargar los filtros.',
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(filterOptionsProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
              data: _options,
            ),
            Text('Precio', style: text.titleSmall),
            RangeSlider(
              values: _price,
              min: _full.start,
              max: _full.end,
              divisions: 25,
              labels: RangeLabels(
                '\$${_price.start.round()}',
                '\$${_price.end.round()}',
              ),
              onChanged: (v) => setState(() => _price = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Solo disponibles'),
              value: _onlyAvailable,
              onChanged: (v) => setState(() => _onlyAvailable = v),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                TextButton(onPressed: _clear, child: const Text('Limpiar')),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_draft),
                  child: Text(label ?? 'Ver resultados'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _options(FilterOptions o) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Género', style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final g in o.genres)
              ChoiceChip(
                label: Text(g),
                selected: _genre == g,
                onSelected: (on) => setState(() => _genre = on ? g : null),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<String?>(
          // Rebuilt on change so "Limpiar" also resets it.
          key: ValueKey('store-$_storeId'),
          initialValue: _storeId,
          decoration: const InputDecoration(labelText: 'Establecimiento'),
          items: [
            const DropdownMenuItem(child: Text('Todos')),
            for (final s in o.stores)
              DropdownMenuItem(value: s.id, child: Text(s.name)),
          ],
          onChanged: (id) => setState(() => _storeId = id),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
