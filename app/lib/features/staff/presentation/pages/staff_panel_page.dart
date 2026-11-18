import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:bookia_mobile/features/staff/domain/entities/store_panel.dart';
import 'package:bookia_mobile/features/staff/presentation/controllers/store_panel_controller.dart';
import 'package:bookia_mobile/features/staff/presentation/widgets/panel_indicators.dart';
import 'package:bookia_mobile/features/staff/presentation/widgets/pending_reservation_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen 16 Panel de tienda: indicators and the reservations to confirm.
class StaffPanelPage extends ConsumerWidget {
  const StaffPanelPage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storePanelProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de tienda'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => e is PasswordChangeRequiredFailure
            ? _Message(
                'Antes de usar el panel debes cambiar tu contraseña.',
                action: TextButton(
                  onPressed: () => context.go(AppRoutes.profile),
                  child: const Text('Ir a Perfil'),
                ),
              )
            : _Message(
                e is Failure ? e.message : 'No pudimos cargar el panel.',
                action: TextButton(
                  onPressed: () => ref.invalidate(storePanelProvider),
                  child: const Text('Reintentar'),
                ),
              ),
        data: (panel) => _PanelBody(panel: panel),
      ),
    );
  }
}

class _PanelBody extends ConsumerWidget {
  const _PanelBody({required this.panel});

  final StorePanel panel;

  /// Runs a confirm or reject and shows the reason when the API refuses.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Failure catch (failure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }

  Future<bool> _askReject(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rechazar reserva'),
          content: const Text(
            'Los ejemplares volverán a estar disponibles. '
            '¿Quieres rechazar esta reserva?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, rechazar'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final controller = ref.read(storePanelProvider.notifier);
    final pending = panel.pending;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          panel.store?.name ?? 'Todas las librerías',
          style: text.headlineSmall,
        ),
        Text('Hola, ${panel.profile.name}'),
        const SizedBox(height: AppSpacing.lg),
        PanelIndicators(panel: panel, now: DateTime.now()),
        const SizedBox(height: AppSpacing.xl),
        Text('Por confirmar (${pending.length})', style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (pending.isEmpty)
          const Text('No hay reservas por confirmar.')
        else
          for (final r in pending)
            PendingReservationTile(
              key: ValueKey(r.id),
              reservation: r,
              onConfirm: () => _run(context, () => controller.confirm(r.id)),
              onReject: () async {
                if (!await _askReject(context)) return;
                if (context.mounted) {
                  await _run(context, () => controller.reject(r.id));
                }
              },
            ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    ),
  );
}
