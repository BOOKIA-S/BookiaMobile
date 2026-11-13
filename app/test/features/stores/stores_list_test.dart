import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/domain/repositories/store_repository.dart';
import 'package:bookia_mobile/features/stores/presentation/controllers/stores_list_controller.dart';
import 'package:bookia_mobile/features/stores/presentation/pages/stores_list_page.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:bookia_mobile/features/stores/presentation/widgets/store_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockStoreRepository extends Mock implements StoreRepository {}

Store store(String id, {double? km}) =>
    Store(id: id, name: 'Librería $id', address: 'Calle $id', distanceKm: km);

void main() {
  late _MockStoreRepository repo;
  setUp(() => repo = _MockStoreRepository());

  void answer(Future<List<Store>> Function() result) => when(
    () => repo.getStores(
      lat: any(named: 'lat'),
      lng: any(named: 'lng'),
    ),
  ).thenAnswer((_) => result());

  group('StoresListController', () {
    Future<List<Store>> load({({double lat, double lng})? position}) async {
      final c = ProviderContainer(
        overrides: [
          storeRepositoryProvider.overrideWithValue(repo),
          userPositionProvider.overrideWithValue(position),
        ],
      );
      addTearDown(c.dispose);
      final sub = c.listen(storesListProvider, (_, _) {});
      addTearDown(sub.close);
      return c.read(storesListProvider.future);
    }

    test('without a position it asks for the stores by name', () async {
      answer(() async => [store('a')]);

      final stores = await load();

      expect(stores, hasLength(1));
      verify(() => repo.getStores(lat: null, lng: null)).called(1);
    });

    test('with a position it asks for the nearest stores', () async {
      answer(() async => [store('a', km: 0.5)]);

      await load(position: (lat: 20.17, lng: -98.05));

      verify(() => repo.getStores(lat: 20.17, lng: -98.05)).called(1);
    });
  });

  group('StoresListPage', () {
    GoRouter router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const StoresListPage()),
        GoRoute(
          path: AppRoutes.storeDetail,
          builder: (_, state) => Text('detalle ${state.pathParameters['id']}'),
        ),
      ],
    );

    Future<void> pump(WidgetTester tester) => tester.pumpWidget(
      ProviderScope(
        overrides: [storeRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(routerConfig: router()),
      ),
    );

    testWidgets('lists the stores with their distance when known', (
      tester,
    ) async {
      answer(
        () async => [store('a', km: 0.85), store('b', km: 1.34), store('c')],
      );
      await pump(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('Librería a'), findsOneWidget);
      expect(find.text('Calle b'), findsOneWidget);
      expect(find.text('850 m'), findsOneWidget);
      expect(find.text('1.3 km'), findsOneWidget);
      expect(find.byType(StoreTile), findsNWidgets(3));
    });

    testWidgets('keeps the order given by the repository', (tester) async {
      answer(() async => [store('z', km: 0.2), store('a', km: 3)]);
      await pump(tester);
      await tester.pumpAndSettle();

      final first = tester.getTopLeft(find.text('Librería z')).dy;
      final second = tester.getTopLeft(find.text('Librería a')).dy;
      expect(first, lessThan(second));
    });

    testWidgets('tapping a store opens its detail', (tester) async {
      answer(() async => [store('s1')]);
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Librería s1'));
      await tester.pumpAndSettle();

      expect(find.text('detalle s1'), findsOneWidget);
    });

    testWidgets('an empty list shows an explanation', (tester) async {
      answer(() async => const []);
      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Aún no hay librerías'), findsOneWidget);
    });

    testWidgets('an error shows its message and retries', (tester) async {
      answer(() => Future.error(const NetworkFailure()));
      await pump(tester);
      await tester.pumpAndSettle();
      expect(find.text(const NetworkFailure().message), findsOneWidget);

      answer(() async => [store('a')]);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Librería a'), findsOneWidget);
    });
  });

  test('distances under a kilometer are shown in meters', () {
    expect(StoreTile.formatDistance(0.85), '850 m');
    expect(StoreTile.formatDistance(0.004), '4 m');
    expect(StoreTile.formatDistance(1), '1.0 km');
    expect(StoreTile.formatDistance(12.34), '12.3 km');
  });
}
