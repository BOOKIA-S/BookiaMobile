import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/favorites/favorite_book.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/profile/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen 15 → Favoritos: the books saved by the reader.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: switch (session) {
        GuestSession() => _Message(
          text: 'Inicia sesión para ver tus favoritos.',
          action: TextButton(
            onPressed: () => context.go(AppRoutes.signIn()),
            child: const Text('Iniciar sesión'),
          ),
        ),
        SignedInSession(role: final role) when role != 'reader' =>
          const _Message(text: 'Solo las cuentas de lector guardan favoritos.'),
        _ => const _FavoritesList(),
      },
    );
  }
}

class _FavoritesList extends ConsumerWidget {
  const _FavoritesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoriteBooksProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Message(
        text: error is Failure
            ? error.message
            : 'No pudimos cargar tus favoritos.',
        action: TextButton(
          onPressed: () => ref.invalidate(favoriteBooksProvider),
          child: const Text('Reintentar'),
        ),
      ),
      data: (books) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoriteBooksProvider);
          await ref.read(favoriteBooksProvider.future);
        },
        child: books.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const _Message(
                    text:
                        'Aún no tienes libros favoritos. Guarda uno desde '
                        'la ficha de un libro.',
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.search),
                      child: const Text('Buscar libros'),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: books.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _FavoriteTile(book: books[i]),
              ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.book});

  final FavoriteBook book;

  @override
  Widget build(BuildContext context) {
    final details = [book.genre, book.publisher].nonNulls.toList();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.menu_book_outlined),
        title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [book.author, ...details].where((s) => s.isNotEmpty).join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push<void>(AppRoutes.book(book.id)),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});

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
