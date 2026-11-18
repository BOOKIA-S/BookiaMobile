import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation_status.dart';
import 'package:bookia_mobile/features/reservations/presentation/formatters.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/expiry_countdown.dart';
import 'package:flutter/material.dart';

/// One reservation of screen 12. The actions come from its status (PAT-10):
/// only an active reservation offers "Ver código" and "Cancelar".
class ReservationCard extends StatelessWidget {
  const ReservationCard({
    required this.reservation,
    required this.onShowCode,
    required this.onCancel,
    this.now = DateTime.now,
    super.key,
  });

  final Reservation reservation;
  final VoidCallback onShowCode;
  final VoidCallback onCancel;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = reservation.status;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  status.label,
                  style: text.labelLarge?.copyWith(color: statusColor(status)),
                ),
                const Spacer(),
                Text(reservation.shortCode, style: text.labelLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              reservation.book?.title ?? 'Libro reservado',
              style: text.titleMedium,
            ),
            Text(reservation.store?.name ?? 'Librería', style: text.bodySmall),
            Text(
              '${reservation.quantity} '
              '${reservation.quantity == 1 ? 'ejemplar' : 'ejemplares'} · '
              '${mxn.format(reservation.total)}',
              style: text.bodySmall,
            ),
            if (status.isActive) ...[
              const SizedBox(height: AppSpacing.xs),
              ExpiryCountdown(expiresAt: reservation.expiresAt, now: now),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status.canCancel)
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancelar'),
                    ),
                  FilledButton.tonal(
                    onPressed: onShowCode,
                    child: const Text('Ver código'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Color of each status on screen 12.
Color? statusColor(ReservationStatus status) => switch (status) {
  Pending() => AppColors.warning,
  Confirmed() || Delivered() => AppColors.success,
  Cancelled() ||
  Expired() ||
  UnknownReservationStatus() => AppColors.textSecondary,
};
