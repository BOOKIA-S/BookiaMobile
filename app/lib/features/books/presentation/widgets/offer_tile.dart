import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final mxn = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

/// One row of "Dónde comprarlo": store, address, price and copies.
class OfferTile extends StatelessWidget {
  const OfferTile({required this.offer, this.isBestPrice = false, super.key});

  final BookOffer offer;

  /// Cheapest store that has copies.
  final bool isBestPrice;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final address = offer.store.address;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.store.name, style: text.titleSmall),
                  if (address != null) Text(address, style: text.bodySmall),
                  if (isBestPrice)
                    Text(
                      'Mejor precio',
                      style: text.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(mxn.format(offer.price), style: text.titleMedium),
                StockLabel(offer: offer),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "6 disponibles" (green), "Últimas 2" (amber) or "Agotado" (grey).
class StockLabel extends StatelessWidget {
  const StockLabel({required this.offer, super.key});

  final BookOffer offer;

  @override
  Widget build(BuildContext context) {
    final (label, color) = !offer.isAvailable
        ? ('Agotado', AppColors.textSecondary)
        : offer.isLow
        ? (
            offer.stock == 1 ? 'Última pieza' : 'Últimas ${offer.stock}',
            AppColors.warning,
          )
        : ('${offer.stock} disponibles', AppColors.success);
    return Text(label, style: TextStyle(color: color, fontSize: 12));
  }
}
