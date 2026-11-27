import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/favorites/favorites_repository.dart';
import 'package:bookia_mobile/core/favorites/favorites_repository_impl.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/core/utils/external_launcher.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/domain/repositories/book_repository.dart';
import 'package:bookia_mobile/features/books/presentation/controllers/favorites_controller.dart';
import 'package:bookia_mobile/features/books/presentation/pages/book_detail_page.dart';
import 'package:bookia_mobile/features/books/presentation/providers.dart';
import 'package:bookia_mobile/features/books/presentation/widgets/book_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_http_adapter.dart';

class _MockBooks extends Mock implements BookRepository {}

class _MockFavorites extends Mock implements FavoritesRepository {}

class _FakeLauncher implements ExternalLauncher {
  final calls = <Uri>[];
  bool result = true;

  @override
  Future<bool> open(Uri uri) async {
    calls.add(uri);
    return result;
  }
}

const reader = SignedInSession(name: 'Ana', role: 'reader');

const paramo = Book(
  id: 'b1',
  title: 'Pedro Páramo',
  author: 'Juan Rulfo',
  isbn: '9786071612342',
  offers: [
    BookOffer(
      id: 'o1',
      price: 95.5,
      stock: 2,
      store: OfferStore(id: 's1', name: 'Sol'),
    ),
  ],
);

void main() {
  group('FavoritesRepositoryImpl', () {
    test('GET /favorites returns the saved ids', () async {
      final adapter = FakeHttpAdapter(200, {
        'items': [
          {'_id': 'b1', 'title': 'Aura'},
          {'_id': 'b2', 'title': 'Pedro Páramo'},
        ],
      });
      final ids = await FavoritesRepositoryImpl(fakeApiClient(adapter)).ids();
      expect(adapter.last!.uri.path, '/api/favorites');
      expect(ids, {'b1', 'b2'});
    });

    test('PUT and DELETE /favorites/:bookId return book_ids', () async {
      final put = FakeHttpAdapter(200, {
        'book_ids': ['b1', 'b2'],
      });
      expect(await FavoritesRepositoryImpl(fakeApiClient(put)).add('b2'), {
        'b1',
        'b2',
      });
      expect(put.last!.method, 'PUT');
      expect(put.last!.uri.path, '/api/favorites/b2');

      final delete = FakeHttpAdapter(200, {'book_ids': <String>[]});
      expect(
        await FavoritesRepositoryImpl(fakeApiClient(delete)).remove('b2'),
        isEmpty,
      );
      expect(delete.last!.method, 'DELETE');
    });
  });

  group('FavoritesController', () {
    late _MockFavorites favorites;
    setUp(() => favorites = _MockFavorites());

    ProviderContainer container(SessionStatus session) {
      final c = ProviderContainer(
        overrides: [favoritesRepositoryProvider.overrideWithValue(favorites)],
      );
      addTearDown(c.dispose);
      c.read(currentSessionProvider.notifier).set(session);
      return c;
    }

    test('a visitor has no favorites and the API is not called', () async {
      final c = container(const GuestSession());
      expect(await c.read(favoritesProvider.future), isEmpty);
      verifyZeroInteractions(favorites);
    });

    test('a failed save brings back the previous ids', () async {
      when(favorites.ids).thenAnswer((_) async => {'b9'});
      when(() => favorites.add('b1'))
          .thenAnswer((_) => Future.error(const NetworkFailure()));
      final c = container(reader);
      await c.read(favoritesProvider.future);

      await expectLater(
        c.read(favoritesProvider.notifier).toggle('b1'),
        throwsA(isA<NetworkFailure>()),
      );
      expect(c.read(favoritesProvider).value, {'b9'});
    });
  });

  test('shareText says where and from how much', () {
    expect(
      shareText(paramo),
      '«Pedro Páramo», de Juan Rulfo.\n'
      r'Está en 1 librería de Huauchinango desde $95.50.'
      '\nISBN 9786071612342\n'
      'Lo encontré en BOOKIA.',
    );
  });

  group('screen 07 actions', () {
    late _MockBooks books;
    late _MockFavorites favorites;
    late _FakeLauncher launcher;
    setUp(() {
      books = _MockBooks();
      favorites = _MockFavorites();
      launcher = _FakeLauncher();
      when(() => books.getById('b1')).thenAnswer((_) async => paramo);
    });

    Future<void> pump(WidgetTester tester, SessionStatus session) async {
      final c = ProviderContainer(
        overrides: [
          bookRepositoryProvider.overrideWithValue(books),
          favoritesRepositoryProvider.overrideWithValue(favorites),
          externalLauncherProvider.overrideWithValue(launcher),
        ],
      );
      addTearDown(c.dispose);
      c.read(currentSessionProvider.notifier).set(session);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: BookDetailPage(bookId: 'b1')),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a reader removes a saved book', (tester) async {
      when(favorites.ids).thenAnswer((_) async => {'b1'});
      when(() => favorites.remove('b1')).thenAnswer((_) async => <String>{});
      await pump(tester, reader);

      await tester.tap(find.byTooltip('Quitar de favoritos'));
      await tester.pumpAndSettle();
      expect(find.text('Quitado de favoritos.'), findsOneWidget);
      expect(find.byTooltip('Guardar en favoritos'), findsOneWidget);
    });

    testWidgets('a visitor is invited to sign in', (tester) async {
      await pump(tester, const GuestSession());
      await tester.tap(find.byTooltip('Guardar en favoritos'));
      await tester.pump();
      expect(
        find.text('Inicia sesión para guardar favoritos.'),
        findsOneWidget,
      );
      verifyZeroInteractions(favorites);
    });

    testWidgets('staff are told only readers keep favorites', (tester) async {
      await pump(tester, const SignedInSession(name: 'Tienda', role: 'admin'));
      await tester.tap(find.byTooltip('Guardar en favoritos'));
      await tester.pump();
      expect(
        find.text('Solo las cuentas de lector guardan favoritos.'),
        findsOneWidget,
      );
    });

    testWidgets('Copiar puts the message on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pump(tester, const GuestSession());

      await tester.tap(find.byTooltip('Compartir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copiar'));
      await tester.pumpAndSettle();
      expect(copied, shareText(paramo));
      expect(find.text('Copiado. Pégalo donde quieras.'), findsOneWidget);
    });

    testWidgets('WhatsApp opens wa.me with the message', (tester) async {
      await pump(tester, const GuestSession());
      await tester.tap(find.byTooltip('Compartir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar por WhatsApp'));
      await tester.pumpAndSettle();

      expect(launcher.calls.single.host, 'wa.me');
      expect(launcher.calls.single.queryParameters['text'], shareText(paramo));
    });
  });
}
