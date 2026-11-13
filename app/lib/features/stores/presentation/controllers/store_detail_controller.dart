import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) of screen 09: loads one store with its catalog.
class StoreDetailController extends AsyncNotifier<StoreDetail> {
  StoreDetailController(this.storeId);

  final String storeId;

  @override
  Future<StoreDetail> build() =>
      ref.read(storeRepositoryProvider).getStore(storeId);
}

final storeDetailProvider = AsyncNotifierProvider.autoDispose
    .family<StoreDetailController, StoreDetail, String>(
      StoreDetailController.new,
    );
