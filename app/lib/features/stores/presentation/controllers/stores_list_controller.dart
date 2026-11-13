import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) of the store list: nearest first when the position of
/// the user is known, by name otherwise.
class StoresListController extends AsyncNotifier<List<Store>> {
  @override
  Future<List<Store>> build() {
    final position = ref.watch(userPositionProvider);
    return ref
        .read(storeRepositoryProvider)
        .getStores(lat: position?.lat, lng: position?.lng);
  }
}

final storesListProvider =
    AsyncNotifierProvider.autoDispose<StoresListController, List<Store>>(
      StoresListController.new,
    );
