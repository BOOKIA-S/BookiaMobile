import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// "21/11 18:05" in the phone's time zone, without loading locale data.
String savedAtLabel(DateTime value) {
  final t = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.day}/${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
}

/// Tells the reader that screen 04 shows a search saved on the phone (I2-10).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    required this.savedAt,
    required this.onRetry,
    super.key,
  });

  final DateTime savedAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: scheme.onSecondaryContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Sin conexión. Resultados guardados el ${savedAtLabel(savedAt)}; '
                'precios y existencias pueden haber cambiado.',
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
