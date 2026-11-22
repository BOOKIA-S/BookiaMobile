import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/home/presentation/widgets/genre_chips.dart';
import 'package:bookia_mobile/features/home/presentation/widgets/most_searched_carousel.dart';
import 'package:bookia_mobile/features/home/presentation/widgets/nearby_stores_section.dart';
import 'package:bookia_mobile/features/search/presentation/search_query.dart';
import 'package:bookia_mobile/features/search/presentation/widgets/recent_searches_chips.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Screen 03 Inicio: search bar, recent searches, genres, most searched
/// books and nearby stores.
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
            decoration: InputDecoration(
              hintText: 'Título, autor o ISBN',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Escanear ISBN',
                onPressed: () => context.push<void>(AppRoutes.scan),
              ),
            ),
            onSubmitted: (q) {
              if (q.trim().isNotEmpty) _search(context, {'q': q.trim()});
            },
          ),
          RecentSearchesChips(
            onSelected: (s) => _search(
              context,
              searchQueryParams((q: s.q, filters: s.filters)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Géneros', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          GenreChips(onSelected: (g) => _search(context, {'genre': g})),
          const SizedBox(height: AppSpacing.xl),
          Text('Más buscados', style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          const MostSearchedCarousel(),
          const SizedBox(height: AppSpacing.xl),
          Text('Librerías cerca de ti', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const NearbyStoresSection(),
        ],
      ),
    );
  }
}
