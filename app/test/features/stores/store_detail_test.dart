import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/domain/repositories/store_repository.dart';
import 'package:bookia_mobile/features/stores/presentation/controllers/store_detail_controller.dart';
import 'package:bookia_mobile/features/stores/presentation/pages/store_detail_page.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStoreRepository extends Mock implements StoreRepository {}

StoreOffer offer(String id, {int stock = 6, double price = 75}) => StoreOffer(
  id: id,
  bookId: 'b-$id',
  title: 'Libro $id',
  author: 'Autor',
  price: price,
  stock: stock,
  isAvailable: stock > 0,
);

StoreDetail detail({List<StoreOffer>? offers, String? phone}) => StoreDetail(
  store: Store(
    id: 's1',
    name: 'Librería Azalea',
    address: 'Av. Benito Juárez 112',
    phone: phone,
    schedule: 'Lun–Sáb 9:00–20:00',
  ),
  offers: offers ?? [offer('a'), offer('b', stock: 2), offer('c', stock: 0)],
);

void main() {
  late _MockStoreRepository repo;
  setUp(() => repo = _MockStoreRepository());

  void answer(Future<StoreDetail> Function() result) =>
      when(() => repo.getStore('s1')).thenAnswer((_) => result());

  test('the controller loads the store by id', () async {
    answer(() async => detail());
    final c = ProviderContainer(
      overrides: [storeRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(storeDetailProvider('s1'), (_, _) {});
    addTearDown(sub.close);

    final loaded = await c.read(storeDetailProvider('s1').future);

    expect(loaded.store.name, 'Librería Azalea');
    verify(() => repo.getStore('s1')).called(1);
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [storeRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: StoreDetailPage(storeId: 's1')),
    ),
  );

  testWidgets('shows the store data and its catalog with stock badges', (
    tester,
  ) async {
    answer(() async => detail(phone: '776 762 0145'));
    await pump(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Librería Azalea'), findsNWidgets(2));
    expect(find.text('Av. Benito Juárez 112'), findsOneWidget);
    expect(find.text('Lun–Sáb 9:00–20:00'), findsOneWidget);
    expect(find.text('776 762 0145'), findsOneWidget);
    expect(find.text('Catálogo (3)'), findsOneWidget);
    expect(find.text(r'$75.00'), findsNWidgets(3));
    expect(find.text('6 disponibles'), findsOneWidget);
    expect(find.text('Últimas 2'), findsOneWidget);
    expect(find.text('Agotado'), findsOneWidget);
  });

  testWidgets('hides the phone row when the store has none', (tester) async {
    answer(() async => detail());
    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.phone_outlined), findsNothing);
  });

  testWidgets('an empty catalog shows an explanation', (tester) async {
    answer(() async => detail(offers: const []));
    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Catálogo (0)'), findsOneWidget);
    expect(find.textContaining('aún no tiene libros'), findsOneWidget);
  });

  testWidgets('an error shows its message and retries', (tester) async {
    answer(() => Future.error(const NetworkFailure()));
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text(const NetworkFailure().message), findsOneWidget);

    answer(() async => detail());
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Catálogo (3)'), findsOneWidget);
  });
}
