import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_controller.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_state.dart';
import 'package:bookia_mobile/features/reservations/presentation/formatters.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/quantity_selector.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/reserve_outcome_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Form of screen 10 and its three states: prepared/failed, sending and an
/// uncertain outcome that must not be treated as a new reservation.
class ReserveForm extends ConsumerWidget {
  const ReserveForm({required this.reserveKey, required this.state, super.key});

  final ReserveKey reserveKey;
  final ReserveState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = reserveControllerProvider(reserveKey);
    final controller = ref.read(provider.notifier);
    final session = ref.watch(currentSessionProvider);
    final isReader = session is SignedInSession && session.role == 'reader';
    final offer = state.offer;
    final soldOut = !offer.isAvailable;
    final text = Theme.of(context).textTheme;

    void openCandidate(Reservation candidate) {
      final location = Uri(
        path: AppRoutes.reservationReady(candidate.id),
        queryParameters: {'recovered': '1'},
      ).toString();
      context.push(location, extra: candidate);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(offer.bookTitle, style: text.headlineSmall),
        Text(offer.bookAuthor, style: text.titleMedium),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.storefront_outlined,
              semanticLabel: 'Librería',
            ),
            title: Text(offer.storeName),
            subtitle: offer.storeAddress == null
                ? null
                : Text(offer.storeAddress!),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Precio unitario', style: text.bodySmall),
                Text(mxn.format(offer.price), style: text.titleLarge),
              ],
            ),
            Text(
              soldOut ? 'Agotado' : '${offer.stock} disponibles',
              style: TextStyle(
                color: soldOut ? AppColors.textSecondary : AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!soldOut) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cantidad', style: text.titleMedium),
              QuantitySelector(
                value: state.quantity,
                max: state.maxQuantity,
                enabled: !state.isBusy,
                onIncrement: controller.increment,
                onDecrement: controller.decrement,
              ),
            ],
          ),
          Text(
            'Máximo ${state.maxQuantity} por reserva',
            style: text.bodySmall,
          ),
          const Divider(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('Total a pagar en tienda', style: text.titleMedium),
              ),
              Text(mxn.format(state.total), style: text.headlineSmall),
            ],
          ),
          Text(
            'El total se confirma con el precio registrado por la librería.',
            style: text.bodySmall,
          ),
        ] else
          const Text('Esta librería ya no tiene ejemplares de este libro.'),
        const SizedBox(height: AppSpacing.lg),
        const _Note(
          icon: Icons.schedule,
          text: 'Tu reserva vence 48 horas después de crearla.',
        ),
        const _Note(
          icon: Icons.info_outline,
          text: 'Puedes tener hasta 10 reservas activas.',
        ),
        const _Note(
          icon: Icons.payments_outlined,
          text: 'Sin pago en línea. Puedes cancelar cuando quieras',
        ),
        if (state.notice != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.notice!,
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (!isReader)
          _ReaderOnlyNotice(
            isGuest: session is! SignedInSession,
            next: AppRoutes.reserve(reserveKey.bookId, reserveKey.offerId),
          )
        else if (state.isLocked)
          ReserveOutcomeCard(
            state: state,
            onVerify: controller.verify,
            onAbandon: controller.abandon,
            onOpen: openCandidate,
          )
        else
          FilledButton(
            onPressed: state.isBusy || soldOut
                ? null
                : () => controller.submit(),
            child: state.isBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirmar reserva'),
          ),
        if (state.failure != null && !state.isLocked) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            state.failure!.message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

/// Guests can sign in and come back to this same offer; staff get an
/// explanation instead of a login loop.
class _ReaderOnlyNotice extends StatelessWidget {
  const _ReaderOnlyNotice({required this.isGuest, required this.next});

  final bool isGuest;
  final String next;

  @override
  Widget build(BuildContext context) {
    if (!isGuest) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Solo las cuentas de lector pueden reservar.'),
              TextButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Inicia sesión para reservar este libro.'),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          onPressed: () => context.go(AppRoutes.signIn(next: next)),
          child: const Text('Iniciar sesión para reservar'),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
