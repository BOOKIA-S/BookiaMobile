import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/stores/presentation/controllers/stores_list_controller.dart';
import 'package:bookia_mobile/features/stores/presentation/widgets/store_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Store list: nearest first when the position is known. Tap opens screen 09.
class StoresListPage extends ConsumerWidget {
  const StoresListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storesListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Librerías')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(
          e is Failure ? e.message : 'No pudimos cargar las librerías.',
          action: TextButton(
            onPressed: () => ref.invalidate(storesListProvider),
            child: const Text('Reintentar'),
          ),
        ),
        data: (stores) => stores.isEmpty
            ? const _Message('Aún no hay librerías registradas.')
            : ListView.separated(
                itemCount: stores.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => StoreTile(
                  store: stores[i],
                  onTap: () => context.push(AppRoutes.store(stores[i].id)),
                ),
              ),
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
