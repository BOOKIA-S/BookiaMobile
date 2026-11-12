import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/stores/data/repositories/store_repository_impl.dart';
import 'package:bookia_mobile/features/stores/domain/repositories/store_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => StoreRepositoryImpl(ref.watch(apiClientProvider)),
);
