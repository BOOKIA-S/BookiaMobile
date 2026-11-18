import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/formatters.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Screen 10 success until screen 11 (I5-08) exists, using only the values
/// confirmed by the server.
class ReserveSuccess extends StatelessWidget {
  const ReserveSuccess({
    required this.reservation,
    required this.bookTitle,
    super.key,
  });

  final Reservation reservation;
  final String bookTitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.success,
          size: 64,
          semanticLabel: 'Reserva creada',
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Reserva creada', style: text.headlineSmall),
        Text(bookTitle, style: text.titleMedium),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total a pagar en tienda', style: text.bodySmall),
                Text(mxn.format(reservation.total), style: text.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text('Cantidad: ${reservation.quantity}'),
                Text('Vence el ${formatDateTime(reservation.expiresAt)}.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text('La librería apartó tus ejemplares por 48 horas.'),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
