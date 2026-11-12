import 'package:bookia_mobile/features/home/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) for the genre chips of the home screen.
class GenresController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() => ref.watch(homeRepositoryProvider).getGenres();

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(homeRepositoryProvider).getGenres(),
    );
  }
}

final genresControllerProvider =
    AsyncNotifierProvider<GenresController, List<String>>(GenresController.new);
