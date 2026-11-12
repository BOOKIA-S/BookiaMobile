import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/presentation/controllers/store_detail_controller.dart';
import 'package:bookia_mobile/features/stores/presentation/widgets/store_offer_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen 09 Ficha de librería: store data and its catalog.
class StoreDetailPage extends ConsumerWidget {
  const StoreDetailPage({required this.storeId, super.key});

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storeDetailProvider(storeId);
    final state = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(title: Text(state.value?.store.name ?? 'Librería')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(
          e is Failure ? e.message : 'No pudimos cargar la librería.',
          action: TextButton(
            onPressed: () => ref.invalidate(provider),
            child: const Text('Reintentar'),
          ),
        ),
        data: (detail) => _StoreBody(detail: detail),
      ),
    );
  }
}

class _StoreBody extends StatelessWidget {
  const _StoreBody({required this.detail});

  final StoreDetail detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final store = detail.store;
    final offers = detail.offers;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(store.name, style: text.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        _InfoRow(Icons.place_outlined, store.address),
        if (store.schedule != null)
          _InfoRow(Icons.schedule_outlined, store.schedule!),
        if (store.phone != null) _InfoRow(Icons.phone_outlined, store.phone!),
        const SizedBox(height: AppSpacing.xl),
        Text('Catálogo (${offers.length})', style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (offers.isEmpty)
          const Text('Esta librería aún no tiene libros publicados.')
        else
          for (final offer in offers) StoreOfferTile(offer: offer),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.value);

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(value)),
      ],
    ),
  );
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
