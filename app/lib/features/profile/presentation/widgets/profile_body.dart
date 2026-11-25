import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';
import 'package:bookia_mobile/features/profile/presentation/widgets/profile_account_section.dart';
import 'package:bookia_mobile/features/profile/presentation/widgets/profile_activity_section.dart';
import 'package:bookia_mobile/features/profile/presentation/widgets/profile_header.dart';
import 'package:bookia_mobile/features/profile/presentation/widgets/profile_preferences_section.dart';
import 'package:bookia_mobile/features/profile/presentation/widgets/profile_states.dart';
import 'package:flutter/material.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({
    required this.user,
    required this.session,
    required this.onEditName,
    required this.onPassword,
    required this.onPrivacy,
    required this.onStaff,
    required this.onLogout,
    required this.onRefresh,
    super.key,
  });

  final ProfileUser user;
  final SignedInSession session;
  final VoidCallback onEditName;
  final VoidCallback onPassword;
  final VoidCallback onPrivacy;
  final VoidCallback onStaff;
  final VoidCallback onLogout;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final reader = user.role == 'reader';
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ProfileHeader(user: user),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onEditName,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar nombre'),
          ),
          if (user.mustChangePassword) ...[
            const SizedBox(height: AppSpacing.md),
            PasswordBanner(onPressed: onPassword),
          ],
          if (reader && !user.mustChangePassword) ...[
            const SizedBox(height: AppSpacing.xl),
            const ProfileActivitySection(),
          ],
          const SizedBox(height: AppSpacing.xl),
          const ProfilePreferencesSection(),
          const SizedBox(height: AppSpacing.xl),
          ProfileAccountSection(
            staff: session.role == 'store_owner' || session.role == 'admin',
            onStaff: onStaff,
            onPassword: onPassword,
            onPrivacy: onPrivacy,
            onLogout: onLogout,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Los datos se muestran desde la cuenta de BOOKIA. No se editan '
            'correo, rol ni identificador desde esta pantalla.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
