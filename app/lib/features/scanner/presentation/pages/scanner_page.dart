import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/scanner/presentation/widgets/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen 06 Escanear ISBN: the camera reads the barcode on the back cover.
class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  String? _code;

  @override
  Widget build(BuildContext context) {
    final camera = ref.watch(cameraViewProvider);
    final code = _code;
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear ISBN')),
      body: Column(
        children: [
          Expanded(child: camera((c) => setState(() => _code = c))),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              code == null
                  ? 'Apunta al código de barras de la contraportada'
                  : 'Código leído: $code',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
