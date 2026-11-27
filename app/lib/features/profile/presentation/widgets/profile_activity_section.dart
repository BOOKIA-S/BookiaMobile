import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/profile/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Mi actividad" of screen 15. Each counter keeps its own error so one
/// failed request never becomes a fake zero for the other.
class ProfileActivitySection extends ConsumerWidget {
  const ProfileActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeReservationsProvider);
    final favorites = ref.watch(favoriteCountProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mi actividad', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: 'Reservas activas',
                value: active,
                onRetry: () => ref.invalidate(activeReservationsProvider),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Metric(
                label: 'Favoritos',
                value: favorites,
                onRetry: () => ref.invalidate(favoriteBooksProvider),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Mis reservas'),
                subtitle: const Text('Activas e historial'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.reservations),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Favoritos'),
                subtitle: const Text('Libros que guardaste'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push<void>(AppRoutes.profileFavorites),
              ),
              const Divider(height: 1),
              const ListTile(
                enabled: false,
                leading: Icon(Icons.notifications_none),
                title: Text('Alertas'),
                subtitle: Text(
                  'No disponible: la API de alertas aún no existe.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.onRetry,
  });

  final String label;
  final AsyncValue<int> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: text.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            value.when(
              loading: () => const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No disponible',
                    style: text.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
              data: (count) => Text('$count', style: text.headlineSmall),
            ),
          ],
        ),
      ),
    );
  }
}
