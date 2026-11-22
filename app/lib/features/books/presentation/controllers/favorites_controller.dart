import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/books/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) of the heart on screen 07: ids of the reader's saved
/// books. Visitors and staff have none, so the API is not called for them.
class FavoritesController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final session = ref.watch(currentSessionProvider);
    if (session is! SignedInSession || session.role != 'reader') return {};
    return ref.watch(favoritesRepositoryProvider).ids();
  }

  /// Saves or removes [bookId] right away and confirms with the API; on a
  /// Failure the previous ids come back and the Failure is rethrown.
  /// Returns true when the book ends up saved.
  Future<bool> toggle(String bookId) async {
    final before = state.value ?? const <String>{};
    final saving = !before.contains(bookId);
    state = AsyncData(
      saving ? {...before, bookId} : ({...before}..remove(bookId)),
    );
    final repo = ref.read(favoritesRepositoryProvider);
    try {
      final after = saving ? await repo.add(bookId) : await repo.remove(bookId);
      if (ref.mounted) state = AsyncData(after);
      return after.contains(bookId);
    } on Object {
      if (ref.mounted) state = AsyncData(before);
      rethrow;
    }
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesController, Set<String>>(
      FavoritesController.new,
      retry: (_, _) => null,
    );
