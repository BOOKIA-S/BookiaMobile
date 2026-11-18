import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_state.dart';
import 'package:bookia_mobile/features/reservations/presentation/formatters.dart';
import 'package:flutter/material.dart';

/// Shown when the outcome of the POST is unknown. It never calls the result
/// "created": it offers candidates for the user to inspect and keeps the
/// attempt locked to prevent a duplicate POST.
class ReserveOutcomeCard extends StatelessWidget {
  const ReserveOutcomeCard({
    required this.state,
    required this.onVerify,
    required this.onAbandon,
    required this.onOpen,
    super.key,
  });

  final ReserveState state;
  final VoidCallback onVerify;
  final VoidCallback onAbandon;
  final ValueChanged<Reservation> onOpen;

  Future<void> _confirmAbandon(BuildContext context) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('¿Descartar la comprobación?'),
        content: const Text(
          'Si la reserva llegó a crearse, seguirá activa en el servidor aunque '
          'descartes esta comprobación. No se cancelará. ¿Permitir otro '
          'intento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Descartar intento'),
          ),
        ],
      ),
    );
    if (discard == true) onAbandon();
  }

  @override
  Widget build(BuildContext context) {
    final attempt = state.attempt!;
    final verifying = state.isVerifying;
    final candidates = state.candidates;
    final text = Theme.of(context).textTheme;
    final showError =
        state.failure != null &&
        state.failure is! NetworkFailure &&
        state.failure is! ServerFailure;

    return Card(
      color: AppColors.warningContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  semanticLabel: 'Resultado incierto',
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    verifying
                        ? 'Comprobando el resultado'
                        : candidates.isEmpty
                        ? 'Resultado incierto'
                        : 'Posibles reservas encontradas',
                    style: text.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Intento: ${attempt.quantity} '
              '${attempt.quantity == 1 ? 'ejemplar' : 'ejemplares'} · '
              '${formatDateTime(attempt.startedAt)}',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (verifying)
              const LinearProgressIndicator()
            else if (candidates.isEmpty)
              const Text(
                'No sabemos si la reserva se creó. Para evitar duplicados, no '
                'puedes confirmar de nuevo. Vuelve a consultar o descarta el '
                'intento con cuidado.',
              )
            else ...[
              const Text(
                'Estas reservas podrían ser de tu intento, pero no podemos '
                'asegurarlo. Revísalas antes de continuar.',
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final candidate in candidates)
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    title: Text(
                      '${candidate.shortCode} · '
                      '${candidate.book?.title ?? state.offer.bookTitle}',
                    ),
                    subtitle: Text(
                      'Cantidad ${candidate.quantity} · '
                      '${candidate.status.label} · '
                      '${candidate.createdAt == null ? '' : formatDateTime(candidate.createdAt!)}',
                    ),
                    trailing: TextButton(
                      onPressed: () => onOpen(candidate),
                      child: const Text('Ver esta reserva'),
                    ),
                  ),
                ),
            ],
            if (showError) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.failure!.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (state.canVerify)
                  TextButton(
                    onPressed: verifying ? null : onVerify,
                    child: const Text('Volver a consultar'),
                  ),
                TextButton(
                  onPressed: verifying ? null : () => _confirmAbandon(context),
                  child: const Text('Descartar intento'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
