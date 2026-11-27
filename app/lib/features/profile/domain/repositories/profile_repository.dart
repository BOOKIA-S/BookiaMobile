import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';

/// Account endpoints used by screen 15. Failures cross this boundary.
abstract interface class ProfileRepository {
  /// `GET /auth/me`.
  Future<ProfileUser> me();

  /// `PATCH /auth/me` with only the name.
  Future<ProfileUser> updateName(String name);

  /// `PATCH /auth/password`; returns the updated user.
  Future<ProfileUser> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Number of `pendiente`/`confirmada` reservations that have not expired.
  Future<int> activeReservationCount();
}
