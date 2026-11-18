/// The signed-in staff account of screen 16 (`GET /auth/me`).
class StaffProfile {
  const StaffProfile({
    required this.name,
    required this.role,
    required this.mustChangePassword,
    this.storeId,
  });

  final String name;

  /// `store_owner` or `admin`.
  final String role;

  /// Only a `store_owner` has a store; an admin sees every store.
  final String? storeId;

  /// The API blocks the desk until the password is changed.
  final bool mustChangePassword;

  bool get isAdmin => role == 'admin';
}
