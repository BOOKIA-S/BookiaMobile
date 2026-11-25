import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';
import 'package:flutter/material.dart';

/// Header of screen 15: who is signed in and since when.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.user, super.key});

  final ProfileUser user;

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String roleLabel(String role) => switch (role) {
    'reader' => 'Lector',
    'store_owner' => 'Encargado de librería',
    'admin' => 'Administrador',
    _ => role,
  };

  static String formatDate(DateTime? value) {
    if (value == null) return 'Fecha no disponible';
    final local = value.toLocal();
    return '${local.day} de ${_months[local.month - 1]} de ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(Icons.person_outline, size: 30),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: text.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.email,
                    style: text.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(roleLabel(user.role), style: text.labelLarge),
                  Text(
                    'Miembro desde ${formatDate(user.createdAt)}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
