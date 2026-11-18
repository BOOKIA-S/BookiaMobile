import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/domain/usecases/walking_minutes.dart';
import 'package:bookia_mobile/features/stores/presentation/widgets/store_actions_bar.dart';
import 'package:bookia_mobile/features/stores/presentation/widgets/store_tile.dart';
import 'package:flutter/material.dart';

/// Quick card of screen 08: name, address, distance and the call and
/// directions actions. Tapping the header opens the store (screen 09).
class StoreQuickCard extends StatelessWidget {
  const StoreQuickCard({
    required this.store,
    required this.onOpen,
    this.distance,
    super.key,
  });

  final Store store;
  final VoidCallback onOpen;

  /// Distance from the user in km, when known.
  final double? distance;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final km = distance;
    return Card(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(store.address),
                  if (km != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${StoreTile.formatDistance(km)} · '
                      '${walkingMinutes(km)} min a pie',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            StoreActionsBar(store: store),
          ],
        ),
      ),
    );
  }
}
