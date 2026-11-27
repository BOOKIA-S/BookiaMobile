import 'package:bookia_mobile/app/di.dart';
import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';
import 'package:bookia_mobile/features/profile/presentation/pages/edit_name_dialog.dart';
import 'package:bookia_mobile/features/profile/presentation/providers.dart';
import 'package:bookia_mobile/features/profile/presentation/widgets/profile_body.dart';
import 'package:bookia_mobile/features/profile/presentation/widgets/profile_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen 15 Perfil. Visitors see the entry to the existing login flow; a
/// signed-in account sees its real data from `GET /auth/me`.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _logoutFailed = false;
  bool _loggingOut = false;

  Future<void> _editName(ProfileUser user) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => EditNameDialog(initialName: user.name),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nombre actualizado.')));
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          'Se borrará el acceso guardado en este teléfono. ¿Quieres salir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _logout();
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() {
      _loggingOut = true;
      _logoutFailed = false;
    });
    try {
      await ref.read(signOutProvider)();
      ref.invalidate(profileProvider);
      ref.invalidate(favoriteBooksProvider);
      ref.invalidate(activeReservationsProvider);
    } on Object {
      if (mounted) setState(() => _logoutFailed = true);
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentSessionProvider, (previous, next) {
      if (next is SignedInSession &&
          (previous is! SignedInSession || previous.id != next.id)) {
        ref.invalidate(profileProvider);
      }
      if (next is GuestSession) {
        ref.invalidate(profileProvider);
        ref.invalidate(favoriteBooksProvider);
        ref.invalidate(activeReservationsProvider);
      }
    });
    final session = ref.watch(currentSessionProvider);
    if (session is! SignedInSession) {
      return ProfileGuest(onSignIn: () => context.go(AppRoutes.signIn()));
    }
    if (_logoutFailed) {
      return ProfileLogoutFailed(retry: _loggingOut ? null : _logout);
    }
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ProfileError(
          error: error,
          onRetry: () => ref.invalidate(profileProvider),
          onSignIn: () => context.go(AppRoutes.auth),
        ),
        data: (user) => ProfileBody(
          user: user,
          session: session,
          onEditName: () => _editName(user),
          onPassword: () => context.push<void>(AppRoutes.profilePassword),
          onPrivacy: () => context.push<void>(AppRoutes.profilePrivacy),
          onStaff: () => context.go(AppRoutes.staff),
          onLogout: _confirmLogout,
          onRefresh: () async {
            ref.invalidate(profileProvider);
            ref.invalidate(activeReservationsProvider);
            ref.invalidate(favoriteBooksProvider);
            await ref.read(profileProvider.future);
          },
        ),
      ),
    );
  }
}
