import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/location/location_providers.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/core/preferences/preferences_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Device preferences of screen 15. Push is shown as unavailable until the
/// Firebase integration is merged; no fake switch is offered.
class ProfilePreferencesSection extends ConsumerStatefulWidget {
  const ProfilePreferencesSection({super.key});

  @override
  ConsumerState<ProfilePreferencesSection> createState() =>
      _ProfilePreferencesSectionState();
}

class _ProfilePreferencesSectionState
    extends ConsumerState<ProfilePreferencesSection> {
  bool _busy = false;

  Future<void> _setLocation(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(appPreferencesProvider.notifier).setUseLocation(value);
      if (value) {
        final access = await ref.read(locationServiceProvider).requestAccess();
        if (access == LocationAccess.granted) {
          await ref.read(currentPositionProvider.notifier).refresh();
        } else if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'No hay permiso de ubicación. Puedes activarlo en los '
                'ajustes del teléfono.',
              ),
            ),
          );
        }
      } else {
        ref.read(currentPositionProvider.notifier).clear();
      }
    } on Object {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos guardar la preferencia. Intenta de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);
    final enabled = prefs.value?.useLocation ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferencias', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Usar mi ubicación'),
                subtitle: Text(
                  enabled
                      ? 'Las librerías se ordenan por distancia. Si el permiso '
                            'está denegado, se muestran sin distancia.'
                      : 'Desactivado: no se pedirán ni enviarán coordenadas.',
                ),
                value: enabled,
                onChanged: prefs.isLoading || _busy ? null : _setLocation,
              ),
              const Divider(height: 1),
              const ListTile(
                enabled: false,
                leading: Icon(Icons.notifications_off_outlined),
                title: Text('Notificaciones push'),
                subtitle: Text(
                  'No disponibles en esta compilación: Firebase no está '
                  'configurado y la integración de I1 sigue en revisión.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
