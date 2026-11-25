import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/favorites/favorite_book.dart';
import 'package:bookia_mobile/core/preferences/preferences_providers.dart';
import 'package:bookia_mobile/core/preferences/preferences_store.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';
import 'package:bookia_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:bookia_mobile/features/profile/presentation/providers.dart';
import 'package:flutter_riverpod/misc.dart';

ProfileUser testProfileUser({
  String id = 'u1',
  String email = 'ana@bookia.mx',
  String name = 'Ana',
  String role = 'reader',
  String? storeId,
  bool mustChangePassword = false,
  DateTime? createdAt,
}) => ProfileUser(
  id: id,
  email: email,
  name: name,
  role: role,
  storeId: storeId,
  mustChangePassword: mustChangePassword,
  createdAt: createdAt ?? DateTime.utc(2026, 11, 9),
);

SignedInSession testSession({
  String id = 'u1',
  String email = 'ana@bookia.mx',
  String name = 'Ana',
  String role = 'reader',
  String? storeId,
  bool mustChangePassword = false,
  DateTime? createdAt,
}) => SignedInSession(
  id: id,
  email: email,
  name: name,
  role: role,
  storeId: storeId,
  mustChangePassword: mustChangePassword,
  createdAt: createdAt ?? DateTime.utc(2026, 11, 9),
);

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({ProfileUser? user, this.activeReservations = 0})
    : user = user ?? testProfileUser();

  ProfileUser user;
  int activeReservations;
  int meCalls = 0;
  int updateCalls = 0;
  int passwordCalls = 0;
  int activityCalls = 0;
  String? lastName;
  Future<ProfileUser> Function()? onMe;
  Future<ProfileUser> Function(String name)? onUpdateName;
  Future<ProfileUser> Function(String current, String next)? onChangePassword;
  Future<int> Function()? onActivity;

  @override
  Future<ProfileUser> me() {
    meCalls++;
    return onMe?.call() ?? Future.value(user);
  }

  @override
  Future<ProfileUser> updateName(String name) {
    updateCalls++;
    lastName = name;
    return onUpdateName?.call(name) ?? Future.value(user);
  }

  @override
  Future<ProfileUser> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    passwordCalls++;
    return onChangePassword?.call(currentPassword, newPassword) ??
        Future.value(user);
  }

  @override
  Future<int> activeReservationCount() {
    activityCalls++;
    return onActivity?.call() ?? Future.value(activeReservations);
  }
}

class FakeSignOut {
  int calls = 0;
  Object? error;

  Future<void> call() async {
    calls++;
    if (error != null) throw error!;
  }
}

/// Store shared by the profile preferences tests.
PreferencesStore memoryPreferences({bool? useLocation}) =>
    MemoryPreferencesStore(
      useLocation == null ? null : {PreferenceKeys.useLocation: useLocation},
    );

/// Convenience failure for tests that need a server error.
const profileFailure = NetworkFailure();

/// Minimal overrides so profile widgets never touch the network or Hive.
List<Override> profileOverrides({
  FakeProfileRepository? repository,
  bool useLocation = true,
  int activeReservations = 0,
  int favorites = 0,
}) => [
  profileRepositoryProvider.overrideWithValue(
    repository ?? FakeProfileRepository(),
  ),
  favoriteBooksProvider.overrideWith(
    (_) async => List<FavoriteBook>.generate(
      favorites,
      (i) => FavoriteBook(id: 'b$i', title: 'Libro $i'),
    ),
  ),
  activeReservationsProvider.overrideWith((_) => activeReservations),
  preferencesStoreProvider.overrideWithValue(
    memoryPreferences(useLocation: useLocation),
  ),
];
