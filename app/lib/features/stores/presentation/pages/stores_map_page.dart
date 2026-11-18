import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/presentation/controllers/stores_list_controller.dart';
import 'package:bookia_mobile/features/stores/presentation/controllers/stores_map_controller.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:bookia_mobile/features/stores/presentation/widgets/store_quick_card.dart';
import 'package:bookia_mobile/features/stores/presentation/widgets/stores_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Builds the map of screen 08; tests replace it, because the real
/// Google Map needs a platform view.
typedef StoresMapBuilder = Widget Function(
  List<Store> stores,
  GeoPoint? user,
  String? selectedId,
  ValueChanged<String?> onSelect,
);

/// Screen 08 Mapa de librerías: a pin per store and a quick card on tap.
class StoresMapPage extends ConsumerWidget {
  const StoresMapPage({this.mapBuilder, super.key});

  final StoresMapBuilder? mapBuilder;

  Widget _defaultMap(
    List<Store> stores,
    GeoPoint? user,
    String? selectedId,
    ValueChanged<String?> onSelect,
  ) => StoresMapView(
    stores: stores,
    user: user,
    selectedId: selectedId,
    onSelect: onSelect,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapStoresProvider);
    final user = ref.watch(userPositionProvider);
    final selectedId = ref.watch(selectedStoreIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(
          e is Failure ? e.message : 'No pudimos cargar las librerías.',
          action: TextButton(
            onPressed: () => ref.invalidate(storesListProvider),
            child: const Text('Reintentar'),
          ),
        ),
        data: (stores) {
          final selected = stores.where((s) => s.id == selectedId).firstOrNull;
          return Stack(
            children: [
              Positioned.fill(
                child: (mapBuilder ?? _defaultMap)(
                  stores,
                  user,
                  selectedId,
                  ref.read(selectedStoreIdProvider.notifier).select,
                ),
              ),
              if (stores.isEmpty)
                const _Message('Aún no hay librerías con ubicación.'),
              if (selected != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: StoreQuickCard(
                    store: selected,
                    distance: distanceToStore(selected, user),
                    onOpen: () => context.push(AppRoutes.store(selected.id)),
                  ),
                ),
            ],
          );
        },
      ),
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
