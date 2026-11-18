import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/scanner/presentation/controllers/scan_controller.dart';
import 'package:bookia_mobile/features/scanner/presentation/widgets/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen 06 Escanear ISBN: reads the barcode on the back cover and opens
/// 07 Ficha de libro when a bookstore in Huauchinango has the book.
class ScannerPage extends ConsumerWidget {
  const ScannerPage({super.key});

  Future<void> _onCode(BuildContext context, WidgetRef ref, String code) async {
    final bookId = await ref.read(scanControllerProvider.notifier).onCode(code);
    if (bookId != null && context.mounted) {
      await context.push<void>(AppRoutes.book(bookId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camera = ref.watch(cameraViewProvider);
    final state = ref.watch(scanControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear ISBN')),
      body: Column(
        children: [
          Expanded(child: camera((code) => _onCode(context, ref, code))),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _ScanMessage(state: state),
          ),
        ],
      ),
    );
  }
}

class _ScanMessage extends StatelessWidget {
  const _ScanMessage({required this.state});

  final ScanState state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return switch (state) {
      ScanIdle() => const Text(
        'Apunta al código de barras de la contraportada',
        textAlign: TextAlign.center,
      ),
      ScanLooking(:final isbn) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Buscando ISBN $isbn…'),
        ],
      ),
      ScanNotIsbn() => const Text(
        'Ese código no es un ISBN. Busca el que empieza con 978 o 979.',
        textAlign: TextAlign.center,
      ),
      ScanNotFound(:final isbn) => Column(
        children: [
          Text(
            'No encontramos este libro en Huauchinango',
            style: text.titleSmall,
          ),
          Text('ISBN $isbn', style: text.bodySmall),
        ],
      ),
      ScanError(:final message) => Text(message, textAlign: TextAlign.center),
    };
  }
}
