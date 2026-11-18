import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/staff/data/datasources/staff_remote_data_source.dart';
import 'package:bookia_mobile/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:bookia_mobile/features/staff/domain/repositories/staff_repository.dart';
import 'package:bookia_mobile/features/staff/domain/usecases/load_store_panel.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider/DI (PAT-03): screens depend on the interfaces, not on data/.
final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) =>
      StaffRepositoryImpl(StaffRemoteDataSource(ref.watch(apiClientProvider))),
);

final loadStorePanelProvider = Provider<LoadStorePanel>(
  (ref) => LoadStorePanel(
    ref.watch(staffRepositoryProvider),
    ref.watch(storeRepositoryProvider),
  ),
);
