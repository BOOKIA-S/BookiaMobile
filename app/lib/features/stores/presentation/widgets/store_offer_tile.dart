import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _mxn = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

/// A catalog row: title, author, price and the stock badge.
class StoreOfferTile extends StatelessWidget {
  const StoreOfferTile({required this.offer, super.key});

  final StoreOffer offer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.title, style: text.titleMedium),
                  Text(offer.author, style: text.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_mxn.format(offer.price), style: text.titleSmall),
                ],
              ),
            ),
            StockBadge(offer: offer),
          ],
        ),
      ),
    );
  }
}

/// "6 disponibles" (green), "Últimas 2" (amber) or "Agotado" (grey).
class StockBadge extends StatelessWidget {
  const StockBadge({required this.offer, super.key});

  final StoreOffer offer;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = !offer.isAvailable
        ? ('Agotado', AppColors.textSecondary, AppColors.sand)
        : offer.isLowStock
        ? (
            'Últimas ${offer.stock}',
            AppColors.warning,
            AppColors.warningContainer,
          )
        : (
            '${offer.stock} disponibles',
            AppColors.success,
            AppColors.successContainer,
          );
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
