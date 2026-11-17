import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef OnCode = void Function(String code);

/// Builds the live camera. Tests override it with a fake that emits codes,
/// because the camera plugin does not run in `flutter test`.
final cameraViewProvider = Provider<Widget Function(OnCode onCode)>(
  (ref) =>
      (onCode) => CameraView(onCode: onCode),
);

/// Back camera that reads EAN-13 barcodes (the ISBN on a book's back cover).
class CameraView extends StatefulWidget {
  const CameraView({required this.onCode, super.key});

  final OnCode onCode;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final code = capture.barcodes.firstOrNull?.rawValue;
          if (code != null) widget.onCode(code);
        },
        errorBuilder: (_, error) => _CameraError(error: error),
      ),
      Align(
        alignment: Alignment.topRight,
        child: IconButton.filledTonal(
          icon: const Icon(Icons.flashlight_on_outlined),
          tooltip: 'Linterna',
          onPressed: () => unawaited(_controller.toggleTorch()),
        ),
      ),
    ],
  );
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error.errorCode == MobileScannerErrorCode.permissionDenied
              ? 'Necesitamos la cámara para leer el ISBN. '
                    'Actívala en los ajustes del teléfono.'
              : 'No pudimos abrir la cámara.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
}
