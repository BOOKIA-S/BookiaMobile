import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_controller.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_state.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/reserve_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen 10 Reservar: book, store, quantity, estimate and the reading notes
/// of the specification. The server remains the authority on stock and price.
class ReservePage extends ConsumerWidget {
  const ReservePage({required this.bookId, required this.offerId, super.key});

  final String bookId;
  final String offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (bookId: bookId, offerId: offerId);
    final provider = reserveControllerProvider(key);
    ref.listen(provider, (previous, next) {
      final created = next.value?.created;
      if (created != null && previous?.value?.created == null) {
        // pushReplacement: returning from screen 11 must not reach the form
        // with a reservation that already exists.
        context.pushReplacement(
          AppRoutes.reservationReady(created.id),
          extra: created,
        );
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Reservar')),
      body: ref
          .watch(provider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorView(
              message: error is Failure
                  ? error.message
                  : 'No pudimos cargar la oferta.',
              onRetry: () => ref.invalidate(provider),
            ),
            data: (state) => switch (state.status) {
              ReserveSucceeded(:final reservation) => _AlreadyReserved(
                reservation: reservation,
                bookTitle: state.offer.bookTitle,
              ),
              _ => ReserveForm(reserveKey: key, state: state),
            },
          ),
    );
  }
}

class _AlreadyReserved extends StatelessWidget {
  const _AlreadyReserved({required this.reservation, required this.bookTitle});

  final Reservation reservation;
  final String bookTitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const Icon(
          Icons.bookmark_added_outlined,
          size: 56,
          semanticLabel: 'Reserva existente',
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Ya tienes esta reserva', style: text.headlineSmall),
        Text(bookTitle, style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('Código ${reservation.shortCode} · ${reservation.status.label}'),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => context.push(
            AppRoutes.reservationReady(reservation.id),
            extra: reservation,
          ),
          child: const Text('Ver reserva'),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
