import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/home/presentation/controllers/genres_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Genre chips with loading, empty, error and data states (PRU-02).
class GenreChips extends ConsumerWidget {
  const GenreChips({required this.onSelected, super.key});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return ref
        .watch(genresControllerProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Column(
            children: [
              Text(e is Failure ? e.message : 'No pudimos cargar los géneros.'),
              TextButton(
                onPressed: ref.read(genresControllerProvider.notifier).retry,
                child: const Text('Reintentar'),
              ),
            ],
          ),
          data: (genres) => genres.isEmpty
              ? Text('Aún no hay géneros.', style: text.bodyMedium)
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final g in genres)
                      ActionChip(
                        label: Text(g),
                        onPressed: () => onSelected(g),
                      ),
                  ],
                ),
        );
  }
}
