import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/favorites/favorite_book.dart';
import 'package:bookia_mobile/core/favorites/favorites_revision.dart';
import 'package:bookia_mobile/core/reservations/reservations_revision.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:bookia_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';
import 'package:bookia_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:bookia_mobile/features/profile/domain/usecases/change_password.dart';
import 'package:bookia_mobile/features/profile/domain/usecases/count_active_reservations.dart';
import 'package:bookia_mobile/features/profile/domain/usecases/load_profile.dart';
import 'package:bookia_mobile/features/profile/domain/usecases/update_name.dart';
import 'package:bookia_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    ProfileRemoteDataSource(ref.watch(apiClientProvider)),
  ),
);

final loadProfileProvider = Provider<LoadProfile>(
  (ref) => LoadProfile(ref.watch(profileRepositoryProvider)),
);

final updateNameProvider = Provider<UpdateName>(
  (ref) => UpdateName(ref.watch(profileRepositoryProvider)),
);

final changePasswordProvider = Provider<ChangePassword>(
  (ref) => ChangePassword(ref.watch(profileRepositoryProvider)),
);

final countActiveReservationsProvider = Provider<CountActiveReservations>(
  (ref) => CountActiveReservations(ref.watch(profileRepositoryProvider)),
);

final profileProvider = AsyncNotifierProvider<ProfileController, ProfileUser>(
  ProfileController.new,
  retry: (_, _) => null,
);

/// Favorites of the current reader, shared by the count and the list.
final favoriteBooksProvider = FutureProvider.autoDispose<List<FavoriteBook>>((
  ref,
) {
  ref.watch(favoritesRevisionProvider);
  final session = ref.watch(currentSessionProvider);
  if (session is! SignedInSession) throw const UnauthorizedFailure();
  if (session.role != 'reader') {
    throw const ForbiddenFailure(
      'Solo las cuentas de lector guardan favoritos.',
    );
  }
  return ref.watch(favoritesRepositoryProvider).list();
});

final favoriteCountProvider = FutureProvider.autoDispose<int>(
  (ref) async => (await ref.watch(favoriteBooksProvider.future)).length,
);

/// Pending/confirmed reservations that have not expired.
final activeReservationsProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(reservationsRevisionProvider);
  final session = ref.watch(currentSessionProvider);
  if (session is! SignedInSession) throw const UnauthorizedFailure();
  return ref.watch(countActiveReservationsProvider).call();
});
