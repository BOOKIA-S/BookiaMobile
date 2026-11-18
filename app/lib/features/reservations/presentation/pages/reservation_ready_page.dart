import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/utils/external_launcher.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/presentation/controllers/reservation_ready_controller.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/pickup_code_card.dart';
import 'package:bookia_mobile/features/reservations/presentation/widgets/reservation_details_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen 11 Reserva lista: pickup code, QR and the confirmed values.
///
/// [initial] is the 201 response when coming from screen 10; it has no
/// populated book/store, so the page also reads `/reservations/mine`, which is
/// the only way to open an existing reservation (there is no GET by id).
class ReservationReadyPage extends ConsumerWidget {
  const ReservationReadyPage({
    required this.reservationId,
    this.initial,
    this.recovered = false,
    super.key,
  });

  final String reservationId;
  final Reservation? initial;

  /// True when opened from a possible match of an uncertain attempt; the
  /// screen must not describe it as newly created.
  final bool recovered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = initial;
    if (fresh != null && fresh.book != null && fresh.store != null) {
      return _ReadyScaffold(reservation: fresh, recovered: recovered);
    }
    final provider = reservationReadyProvider(reservationId);
    return Scaffold(
      appBar: AppBar(title: const Text('Reserva lista')),
      body: ref
          .watch(provider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorView(
              failure: error is Failure ? error : const ServerFailure(),
              reservationId: reservationId,
              onRetry: () => ref.invalidate(provider),
            ),
            data: (reservation) =>
                _ReadyBody(reservation: reservation, recovered: recovered),
          ),
    );
  }
}

class _ReadyScaffold extends StatelessWidget {
  const _ReadyScaffold({required this.reservation, required this.recovered});

  final Reservation reservation;
  final bool recovered;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reserva lista')),
    body: _ReadyBody(reservation: reservation, recovered: recovered),
  );
}

class _ReadyBody extends ConsumerWidget {
  const _ReadyBody({required this.reservation, required this.recovered});

  final Reservation reservation;
  final bool recovered;

  Future<void> _directions(BuildContext context, WidgetRef ref) async {
    final address = reservation.store?.address;
    if (address == null || address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta librería no tiene dirección registrada.'),
        ),
      );
      return;
    }
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address,
    });
    final opened = await ref.read(externalLauncherProvider).open(uri);
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay una app para abrir el mapa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        PickupCodeCard(reservation: reservation, recovered: recovered),
        ReservationDetailsCard(
          reservation: reservation,
          onDirections: reservation.store?.address == null
              ? null
              : () => _directions(context, ref),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.failure,
    required this.reservationId,
    required this.onRetry,
  });

  final Failure failure;
  final String reservationId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(failure.message, textAlign: TextAlign.center),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            if (failure is UnauthorizedFailure)
              FilledButton(
                onPressed: () => context.go(
                  AppRoutes.signIn(
                    next: AppRoutes.reservationReady(reservationId),
                  ),
                ),
                child: const Text('Iniciar sesión'),
              ),
          ],
        ),
      ),
    );
  }
}
