import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:bookia_mobile/features/search/domain/sort/sort_strategy.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quick chips of screen 04: Disponible · Más barato · Más cerca.
class QuickChips extends ConsumerWidget implements PreferredSizeWidget {
  const QuickChips({required this.filters, required this.onChanged, super.key});

  final SearchFilters filters;
  final ValueChanged<SearchFilters> onChanged;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  /// Tapping the active order goes back to the default, by title.
  void _toggleSort(SortOption option) => onChanged(
    filters.copyWith(sort: filters.sort == option ? SortOption.title : option),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearby = ref.watch(canSortByDistanceProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          FilterChip(
            label: const Text('Disponible'),
            selected: filters.onlyAvailable,
            onSelected: (on) => onChanged(filters.copyWith(onlyAvailable: on)),
          ),
          FilterChip(
            label: const Text('Más barato'),
            selected: filters.sort == SortOption.price,
            onSelected: (_) => _toggleSort(SortOption.price),
          ),
          FilterChip(
            label: const Text('Más cerca'),
            tooltip: nearby ? null : 'Activa tu ubicación',
            selected: filters.sort == SortOption.distance,
            onSelected: nearby ? (_) => _toggleSort(SortOption.distance) : null,
          ),
        ],
      ),
    );
  }
}
