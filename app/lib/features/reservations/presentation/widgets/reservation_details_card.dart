import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/formatters.dart';
import 'package:flutter/material.dart';

/// Book, store, quantity, amount and deadline of screen 11, all from the
/// reservation the server returned.
class ReservationDetailsCard extends StatelessWidget {
  const ReservationDetailsCard({
    required this.reservation,
    required this.onDirections,
    super.key,
  });

  final Reservation reservation;

  /// Null when the store has no address, so the action is not offered.
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final book = reservation.book;
    final store = reservation.store;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book?.title ?? 'Libro reservado', style: text.titleMedium),
            if (book != null && book.author.isNotEmpty)
              Text(book.author, style: text.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(store?.name ?? 'Librería', style: text.bodyMedium),
            if (store?.address != null)
              Text(store!.address!, style: text.bodySmall),
            const Divider(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cantidad', style: text.bodyMedium),
                Text('${reservation.quantity}', style: text.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Total a pagar en tienda',
                    style: text.bodyMedium,
                  ),
                ),
                Text(mxn.format(reservation.total), style: text.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Vence el ${formatDateTime(reservation.expiresAt)}.'),
            const SizedBox(height: AppSpacing.md),
            if (onDirections != null)
              OutlinedButton.icon(
                onPressed: onDirections,
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Cómo llegar'),
              )
            else
              const Text('Esta librería no tiene dirección registrada.'),
          ],
        ),
      ),
    );
  }
}
