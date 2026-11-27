import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Account actions at the bottom of screen 15.
class ProfileAccountSection extends StatelessWidget {
  const ProfileAccountSection({
    required this.staff,
    required this.onStaff,
    required this.onPassword,
    required this.onPrivacy,
    required this.onLogout,
    super.key,
  });

  final bool staff;
  final VoidCallback onStaff;
  final VoidCallback onPassword;
  final VoidCallback onPrivacy;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cuenta', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Cambiar contraseña'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onPassword,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Aviso de privacidad'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onPrivacy,
              ),
              if (staff) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Panel de tienda'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onStaff,
                ),
              ],
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout, color: error),
                title: Text('Cerrar sesión', style: TextStyle(color: error)),
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
