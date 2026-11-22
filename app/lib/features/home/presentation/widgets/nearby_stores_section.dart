import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/location/location_providers.dart';
import 'package:bookia_mobile/features/home/presentation/controllers/nearby_stores_controller.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/domain/usecases/walking_minutes.dart';
import 'package:bookia_mobile/features/stores/presentation/widgets/store_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Librerías cerca de ti" of screen 03: the nearest stores with distance
/// and schedule, or an invitation to share the location.
class NearbyStoresSection extends ConsumerWidget {
  const NearbyStoresSection({super.key});

  Future<void> _locate(BuildContext context, WidgetRef ref) async {
    final position = await ref.read(currentPositionProvider.notifier).refresh();
    if (position == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos obtener tu ubicación. Revisa el permiso y el GPS.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = TextButton(
      onPressed: () => context.push<void>(AppRoutes.stores),
      child: const Text('Ver todas las librerías'),
    );
    return ref
        .watch(nearbyStoresProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Row(
            children: [
              Expanded(
                child: Text(
                  e is Failure ? e.message : 'No pudimos cargar las librerías.',
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(nearbyStoresProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
          data: (stores) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stores == null) ...[
                const Text(
                  'Comparte tu ubicación para ver las librerías más cercanas.',
                ),
                TextButton.icon(
                  onPressed: () => _locate(context, ref),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Usar mi ubicación'),
                ),
              ] else if (stores.isEmpty)
                const Text('No hay librerías a menos de 5 km.')
              else
                for (final s in stores) _NearbyTile(store: s),
              all,
            ],
          ),
        );
  }
}

class _NearbyTile extends StatelessWidget {
  const _NearbyTile({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final km = store.distanceKm;
    final distance = km == null
        ? null
        : '${StoreTile.formatDistance(km)} · ${walkingMinutes(km)} min a pie';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.storefront),
        title: Text(store.name),
        subtitle: Text(
          [?distance, ?store.schedule].join('\n'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: distance != null && store.schedule != null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push<void>(AppRoutes.store(store.id)),
      ),
    );
  }
}
