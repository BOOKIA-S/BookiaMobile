import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Short code and QR of the reservation. The QR carries exactly the full `_id`
/// that the store will scan; an inactive reservation never shows one.
class PickupCodeCard extends StatelessWidget {
  const PickupCodeCard({required this.reservation, super.key});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final active = reservation.status.isActive;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              active
                  ? '¡Libro apartado!'
                  : 'Reserva ${reservation.status.label.toLowerCase()}',
              style: text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              label: 'Código de la reserva ${reservation.shortCode}',
              child: Text(
                reservation.shortCode,
                style: text.headlineMedium?.copyWith(letterSpacing: 4),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (active) ...[
              PickupQr(data: reservation.id),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Muestra este código en la librería.',
                style: text.bodySmall,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const Text(
                'Esta reserva ya no está activa.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The QR shown at the counter. [data] is exactly the full reservation `_id`,
/// never a token, an email or the short code.
class PickupQr extends StatelessWidget {
  const PickupQr({required this.data, super.key});

  final String data;

  @override
  Widget build(BuildContext context) => QrImageView(
    data: data,
    version: QrVersions.auto,
    size: 220,
    backgroundColor: Colors.white,
    padding: const EdgeInsets.all(AppSpacing.md),
    semanticsLabel: 'Código QR de la reserva',
  );
}
