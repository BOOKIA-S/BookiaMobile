import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/my_reservations_controller.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/reservation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen 12 Mis reservas: "Activas" (pending, confirmed) and "Historial"
/// (delivered, cancelled, expired), each with a countdown and its actions.
class MyReservationsPage extends ConsumerWidget {
  const MyReservationsPage({this.now = DateTime.now, super.key});

  /// Clock for the countdowns, replaceable in tests.
  final DateTime Function() now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(myReservationsProvider);
    final active = reservations.value?.where((r) => r.status.isActive);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis reservas'),
          bottom: TabBar(
            tabs: [
              Tab(
                text: active == null ? 'Activas' : 'Activas (${active.length})',
              ),
              const Tab(text: 'Historial'),
            ],
          ),
        ),
        body: reservations.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Message(
            text: e is UnauthorizedFailure
                ? 'Inicia sesión para ver tus reservas.'
                : e is Failure
                ? e.message
                : 'No pudimos cargar tus reservas.',
            action: e is UnauthorizedFailure ? 'Iniciar sesión' : 'Reintentar',
            onAction: e is UnauthorizedFailure
                ? () => context.push<void>(AppRoutes.signIn())
                : () => ref.invalidate(myReservationsProvider),
          ),
          data: (items) => TabBarView(
            children: [
              _List(
                items: [
                  for (final r in items)
                    if (r.status.isActive) r,
                ],
                empty: 'No tienes reservas activas. Busca un libro y apártalo.',
                now: now,
              ),
              _List(
                items: [
                  for (final r in items)
                    if (!r.status.isActive) r,
                ],
                empty:
                    'Aquí verás las reservas entregadas, canceladas y '
                    'vencidas.',
                now: now,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.items, required this.empty, required this.now});

  final List<Reservation> items;
  final String empty;
  final DateTime Function() now;

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    Reservation r,
  ) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar la reserva?'),
        content: Text(
          'Liberamos ${r.quantity == 1 ? 'el ejemplar' : 'los ejemplares'} '
          'de ${r.book?.title ?? 'este libro'} para otros lectores.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(myReservationsProvider.notifier).cancel(r.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Reserva ${r.shortCode} cancelada.')),
      );
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return _Message(text: empty);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myReservationsProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final r in items)
            ReservationCard(
              reservation: r,
              now: now,
              onShowCode: () => context.push<void>(
                AppRoutes.reservationReady(r.id),
                extra: r,
              ),
              onCancel: () => _cancel(context, ref, r),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    ),
  );
}
