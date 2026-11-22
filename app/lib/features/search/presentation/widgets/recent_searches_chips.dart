import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/search/domain/entities/recent_search.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Búsquedas recientes" on screen 03: saved on the phone, so they also
/// work without connection (I2-10). Hidden while there are none.
class RecentSearchesChips extends ConsumerWidget {
  const RecentSearchesChips({required this.onSelected, super.key});

  final ValueChanged<RecentSearch> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider).value ?? const [];
    if (recent.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Búsquedas recientes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in recent)
                ActionChip(
                  avatar: const Icon(Icons.history, size: 18),
                  label: Text(s.label),
                  onPressed: () => onSelected(s),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
