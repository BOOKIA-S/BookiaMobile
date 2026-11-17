import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/onboarding/presentation/controllers/location_permission_controller.dart';
import 'package:bookia_mobile/features/onboarding/presentation/widgets/location_map_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen 02: explains why BOOKIA wants the location and asks for it once.
class LocationPermissionPage extends ConsumerWidget {
  const LocationPermissionPage({super.key});

  Future<void> _allow(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(locationPermissionControllerProvider.notifier);
    final access = await controller.allow();
    if (!context.mounted) return;
    if (access == LocationAccess.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La ubicación está bloqueada. Puedes activarla en Ajustes.',
          ),
        ),
      );
    }
    context.go(AppRoutes.home);
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    await ref.read(locationPermissionControllerProvider.notifier).skip();
    if (context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asking = ref.watch(locationPermissionControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LocationMapIllustration(),
                    const SizedBox(height: 32),
                    Semantics(
                      header: true,
                      child: Text(
                        'Encuentra la librería más cercana',
                        style: text.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Usamos tu ubicación solo para ordenar las librerías '
                      'por distancia y trazar la ruta. Nunca la guardamos.',
                      style: text.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: asking ? null : () => _allow(context, ref),
                      icon: asking
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.navigation_outlined),
                      label: const Text('Permitir ubicación'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: asking ? null : () => _skip(context, ref),
                      child: const Text('Ahora no'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
