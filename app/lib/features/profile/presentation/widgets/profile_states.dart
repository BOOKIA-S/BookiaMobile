import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:flutter/material.dart';

class ProfileGuest extends StatelessWidget {
  const ProfileGuest({required this.onSignIn, super.key});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 56),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Inicia sesión para ver tu perfil, tus reservas y tus favoritos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onSignIn,
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProfileError extends StatelessWidget {
  const ProfileError({
    required this.error,
    required this.onRetry,
    required this.onSignIn,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error is Failure
                ? (error as Failure).message
                : 'No pudimos cargar tu perfil.',
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          if (error is UnauthorizedFailure)
            FilledButton(
              onPressed: onSignIn,
              child: const Text('Iniciar sesión'),
            ),
        ],
      ),
    ),
  );
}

class ProfileLogoutFailed extends StatelessWidget {
  const ProfileLogoutFailed({required this.retry, super.key});

  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No pudimos borrar el acceso guardado. La sesión no se cerró y '
              'no mostraremos tus datos mientras el estado sea incierto.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: retry,
              child: const Text('Reintentar cierre de sesión'),
            ),
          ],
        ),
      ),
    ),
  );
}

class PasswordBanner extends StatelessWidget {
  const PasswordBanner({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debes cambiar tu contraseña',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: scheme.error),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'El panel de tienda seguirá bloqueado hasta que cambies la '
              'contraseña temporal.',
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: onPressed,
              child: const Text('Cambiar contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}
