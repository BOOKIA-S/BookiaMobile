import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reserve_controller.dart';
import 'package:bookia_mobile/features/reservations/presentation/formatters.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/quantity_selector.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/reserve_success.dart';
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
            data: (state) => state.created == null
                ? _ReserveForm(reserveKey: key, state: state)
                : ReserveSuccess(
                    reservation: state.created!,
                    bookTitle: state.book.title,
                  ),
          ),
    );
  }
}

class _ReserveForm extends ConsumerWidget {
  const _ReserveForm({required this.reserveKey, required this.state});

  final ReserveKey reserveKey;
  final ReserveState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = reserveControllerProvider(reserveKey);
    final controller = ref.read(provider.notifier);
    final session = ref.watch(currentSessionProvider);
    final isReader = session is SignedInSession && session.role == 'reader';
    final offer = state.offer;
    final soldOut = offer.stock < 1;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(state.book.title, style: text.headlineSmall),
        Text(state.book.author, style: text.titleMedium),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.storefront_outlined,
              semanticLabel: 'Librería',
            ),
            title: Text(offer.store.name),
            subtitle: offer.store.address == null
                ? null
                : Text(offer.store.address!),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Cantidad', style: text.titleMedium),
            QuantitySelector(
              value: state.quantity,
              max: state.maxQuantity,
              enabled: !state.isSubmitting,
              onIncrement: controller.increment,
              onDecrement: controller.decrement,
            ),
          ],
        ),
        Text('Máximo ${state.maxQuantity} por reserva', style: text.bodySmall),
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
        const SizedBox(height: AppSpacing.lg),
        if (soldOut) ...[
          const Text('Esta librería ya no tiene ejemplares de este libro.'),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!isReader)
          _ReaderOnlyNotice(
            isGuest: session is! SignedInSession,
            next: AppRoutes.reserve(reserveKey.bookId, reserveKey.offerId),
          )
        else
          FilledButton(
            onPressed: state.isSubmitting || soldOut
                ? null
                : () => controller.submit(),
            child: state.isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirmar reserva'),
          ),
        if (state.failure != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            state.failure!.message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (state.canVerify) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: state.isSubmitting ? null : () => controller.verify(),
            child: const Text('Comprobar si se creó'),
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
