import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/formatters.dart';
import 'package:flutter/material.dart';

/// A reservation waiting for the staff, with Confirmar and Rechazar. Both
/// buttons are off while one of the actions is running.
class PendingReservationTile extends StatefulWidget {
  const PendingReservationTile({
    required this.reservation,
    required this.onConfirm,
    required this.onReject,
    super.key,
  });

  final Reservation reservation;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onReject;

  @override
  State<PendingReservationTile> createState() => _PendingReservationTileState();
}

class _PendingReservationTileState extends State<PendingReservationTile> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.book?.title ?? 'Libro', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('${r.shortCode} · vence ${formatDateTime(r.expiresAt)}'),
            Text(
              '${r.quantity} × ${mxn.format(r.price)} = ${mxn.format(r.total)}',
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _run(widget.onReject),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : () => _run(widget.onConfirm),
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
