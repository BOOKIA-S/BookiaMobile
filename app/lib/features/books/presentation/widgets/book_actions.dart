import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/core/utils/external_launcher.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/presentation/controllers/favorites_controller.dart';
import 'package:bookia_mobile/features/books/presentation/widgets/offer_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Heart of screen 07. Visitors are invited to sign in, staff are told that
/// only readers keep favorites.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({required this.bookId, super.key});

  final String bookId;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final session = ref.read(currentSessionProvider);
    if (session is! SignedInSession) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Inicia sesión para guardar favoritos.'),
          action: SnackBarAction(
            label: 'Iniciar sesión',
            onPressed: () => context.go(AppRoutes.signIn()),
          ),
        ),
      );
      return;
    }
    if (session.role != 'reader') {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Solo las cuentas de lector guardan favoritos.'),
        ),
      );
      return;
    }
    try {
      final saved = await ref.read(favoritesProvider.notifier).toggle(bookId);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            saved ? 'Guardado en favoritos.' : 'Quitado de favoritos.',
          ),
        ),
      );
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favoritesProvider).value?.contains(bookId) ?? false;
    return IconButton(
      icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
      tooltip: saved ? 'Quitar de favoritos' : 'Guardar en favoritos',
      onPressed: () => _toggle(context, ref),
    );
  }
}

/// Message shared from screen 07: title, author, where and from how much.
String shareText(Book book) {
  final stores = book.offers.where((o) => o.isAvailable).length;
  final minPrice = book.minPrice;
  final where = minPrice == null
      ? 'Por ahora está agotado en Huauchinango.'
      : 'Está en $stores ${stores == 1 ? 'librería' : 'librerías'} de '
            'Huauchinango desde ${mxn.format(minPrice)}.';
  return [
    '«${book.title}», de ${book.author}.',
    where,
    if (book.isbn != null) 'ISBN ${book.isbn}',
    'Lo encontré en BOOKIA.',
  ].join('\n');
}

/// Share without new packages: copy the text or send it by WhatsApp
/// through the ExternalLauncher facade (PAT-11).
class ShareButton extends ConsumerWidget {
  const ShareButton({required this.book, super.key});

  final Book book;

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final text = shareText(book);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Enviar por WhatsApp'),
              onTap: () => Navigator.pop(context, 'whatsapp'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (choice == 'copy') {
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(
        const SnackBar(content: Text('Copiado. Pégalo donde quieras.')),
      );
      return;
    }
    final opened = await ref
        .read(externalLauncherProvider)
        .open(Uri.https('wa.me', '/', {'text': text}));
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No encontramos WhatsApp en este teléfono.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    icon: const Icon(Icons.share_outlined),
    tooltip: 'Compartir',
    onPressed: () => _share(context, ref),
  );
}
