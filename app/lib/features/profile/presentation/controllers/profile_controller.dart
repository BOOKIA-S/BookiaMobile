import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';
import 'package:bookia_mobile/features/profile/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) of screen 15: the authoritative account plus the two
/// mutations allowed from the profile (name and password).
class ProfileController extends AsyncNotifier<ProfileUser> {
  @override
  Future<ProfileUser> build() async {
    final expected = _expectedSession();
    final user = await ref.read(loadProfileProvider).call();
    if (!ref.mounted) return user;
    _ensureSameSession(expected);
    _syncSession(user);
    return user;
  }

  Future<void> updateName(String name) async {
    final expected = _expectedSession();
    final user = await ref.read(updateNameProvider).call(name);
    if (!ref.mounted) return;
    _ensureSameSession(expected);
    _syncSession(user);
    if (ref.mounted) state = AsyncData(user);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final expected = _expectedSession();
    final user = await ref
        .read(changePasswordProvider)
        .call(currentPassword: currentPassword, newPassword: newPassword);
    if (!ref.mounted) return;
    _ensureSameSession(expected);
    _syncSession(user);
    if (ref.mounted) state = AsyncData(user);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  SignedInSession _expectedSession() {
    final session = ref.read(currentSessionProvider);
    if (session is! SignedInSession) throw const UnauthorizedFailure();
    return session;
  }

  /// A late response from a previous account must never update the current
  /// one. The empty-id fallback keeps older tests and sessions working.
  void _ensureSameSession(SignedInSession expected) {
    final current = ref.read(currentSessionProvider);
    if (current is! SignedInSession) throw const UnauthorizedFailure();
    if (expected.id.isNotEmpty && current.id != expected.id) {
      throw const UnauthorizedFailure();
    }
  }

  void _syncSession(ProfileUser user) {
    final current = ref.read(currentSessionProvider);
    if (current is! SignedInSession) return;
    if (current.id.isNotEmpty && current.id != user.id) return;
    final next = SignedInSession(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      storeId: user.storeId,
      mustChangePassword: user.mustChangePassword,
      createdAt: user.createdAt,
    );
    // Avoid notifying the same values: build() watches the session and would
    // otherwise trigger an infinite reload loop.
    if (current.id == next.id &&
        current.email == next.email &&
        current.name == next.name &&
        current.role == next.role &&
        current.storeId == next.storeId &&
        current.mustChangePassword == next.mustChangePassword &&
        current.createdAt == next.createdAt) {
      return;
    }
    ref.read(currentSessionProvider.notifier).set(next);
  }
}
