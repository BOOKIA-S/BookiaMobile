import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/books/domain/entities/book.dart';
import 'package:bookia_mobile/features/books/domain/repositories/book_repository.dart';
import 'package:bookia_mobile/features/books/presentation/providers.dart';
import 'package:bookia_mobile/features/scanner/presentation/widgets/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockBookRepository extends Mock implements BookRepository {}

/// Stands in for the camera: tapping it "reads" [code].
Override fakeCamera(String code) => cameraViewProvider.overrideWithValue(
  (onCode) => Center(
    child: TextButton(
      onPressed: () => onCode(code),
      child: const Text('simular lectura'),
    ),
  ),
);

const isbn = '9780306406157';
const book = Book(id: 'b1', title: 'Pedro Páramo', author: 'Juan Rulfo');

void main() {
  late _MockBookRepository repo;
  setUp(() => repo = _MockBookRepository());

  Future<void> openScanner(WidgetTester tester, String code) async {
    final router = createRouter(initialLocation: AppRoutes.scan);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...offlineOverrides(),
          bookRepositoryProvider.overrideWithValue(repo),
          fakeCamera(code),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Apunta al código de barras de la contraportada'),
      findsOneWidget,
    );
    await tester.tap(find.text('simular lectura'));
    await tester.pumpAndSettle();
  }

  testWidgets('a known ISBN opens 07 Ficha de libro', (tester) async {
    when(() => repo.findByIsbn(isbn)).thenAnswer((_) async => book);
    when(() => repo.getById('b1')).thenAnswer((_) async => book);
    await openScanner(tester, isbn);
    expect(find.widgetWithText(AppBar, 'Ficha de libro'), findsOneWidget);
    expect(find.text('Pedro Páramo'), findsOneWidget);
  });

  testWidgets('an ISBN no store has says so', (tester) async {
    when(() => repo.findByIsbn(isbn)).thenAnswer((_) async => null);
    await openScanner(tester, isbn);
    expect(
      find.text('No encontramos este libro en Huauchinango'),
      findsOneWidget,
    );
    expect(find.text('ISBN $isbn'), findsOneWidget);
  });

  testWidgets('a code that is not an ISBN never calls the API', (tester) async {
    await openScanner(tester, '4006381333931');
    expect(find.textContaining('no es un ISBN'), findsOneWidget);
    verifyNever(() => repo.findByIsbn(any()));
  });

  testWidgets('a network failure shows its message', (tester) async {
    when(() => repo.findByIsbn(isbn))
        .thenAnswer((_) => Future.error(const NetworkFailure()));
    await openScanner(tester, isbn);
    expect(find.text(const NetworkFailure().message), findsOneWidget);
  });

  testWidgets('the scan button on 03 Inicio opens screen 06', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...offlineOverrides(), fakeCamera(isbn)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Escanear ISBN'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Escanear ISBN'), findsOneWidget);
  });
}
