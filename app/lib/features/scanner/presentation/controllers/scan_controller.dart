import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/books/presentation/providers.dart';
import 'package:bookia_mobile/features/scanner/domain/entities/ean13.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What screen 06 shows under the camera.
sealed class ScanState {
  const ScanState();
}

class ScanIdle extends ScanState {
  const ScanIdle();
}

class ScanLooking extends ScanState {
  const ScanLooking(this.isbn);
  final String isbn;
}

/// A barcode that is not an ISBN (a product code, a bad read).
class ScanNotIsbn extends ScanState {
  const ScanNotIsbn();
}

class ScanNotFound extends ScanState {
  const ScanNotFound(this.isbn);
  final String isbn;
}

class ScanError extends ScanState {
  const ScanError(this.message);
  final String message;
}

/// ViewModel (PAT-02) of screen 06: checks the code and looks the book up.
class ScanController extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanIdle();

  /// Returns the book id to open, or null when there is nothing to open.
  Future<String?> onCode(String code) async {
    if (state is ScanLooking) return null;
    if (!Ean13.isIsbn(code)) {
      state = const ScanNotIsbn();
      return null;
    }
    state = ScanLooking(code);
    try {
      final book = await ref.read(findBookByIsbnProvider)(code);
      if (!ref.mounted) return null;
      state = book == null ? ScanNotFound(code) : const ScanIdle();
      return book?.id;
    } on Failure catch (f) {
      if (ref.mounted) state = ScanError(f.message);
      return null;
    }
  }
}

final scanControllerProvider =
    NotifierProvider.autoDispose<ScanController, ScanState>(ScanController.new);
