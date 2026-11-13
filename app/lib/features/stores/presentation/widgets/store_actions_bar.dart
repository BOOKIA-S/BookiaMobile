import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/utils/external_launcher.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Llamar" and "Cómo llegar" buttons of screen 09.
class StoreActionsBar extends ConsumerWidget {
  const StoreActionsBar({required this.store, super.key});

  final Store store;

  Future<void> _open(BuildContext context, WidgetRef ref, Uri uri) async {
    final opened = await ref.read(externalLauncherProvider).open(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir la aplicación.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = store.callUri;
    const size = Size.fromHeight(AppSpacing.minTouchTarget);
    return Row(
      children: [
        if (call != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: size),
              onPressed: () => _open(context, ref, call),
              icon: const Icon(Icons.call),
              label: const Text('Llamar'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: size),
            onPressed: () => _open(context, ref, store.directionsUri),
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Cómo llegar'),
          ),
        ),
      ],
    );
  }
}
