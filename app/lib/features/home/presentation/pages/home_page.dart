import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/home/presentation/widgets/genre_chips.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Screen 03 Inicio: search bar and genres. Nearby stores and most searched
/// books arrive in I2-11 (S04).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _search(BuildContext context, Map<String, String> query) => context.go(
    Uri(path: AppRoutes.search, queryParameters: query).toString(),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('¿Qué libro buscas hoy?', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          TextField(
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Título, autor o ISBN',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (q) {
              if (q.trim().isNotEmpty) _search(context, {'q': q.trim()});
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Géneros', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          GenreChips(onSelected: (g) => _search(context, {'genre': g})),
        ],
      ),
    );
  }
}
