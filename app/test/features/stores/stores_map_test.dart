import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/domain/repositories/store_repository.dart';
import 'package:bookia_mobile/features/stores/domain/usecases/walking_minutes.dart';
import 'package:bookia_mobile/features/stores/presentation/controllers/stores_list_controller.dart';
import 'package:bookia_mobile/features/stores/presentation/controllers/stores_map_controller.dart';
import 'package:bookia_mobile/features/stores/presentation/pages/stores_map_page.dart';
import 'package:bookia_mobile/features/stores/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockStoreRepository extends Mock implements StoreRepository {}

const _user = (lat: 20.17, lng: -98.05);

Store store(
  String id, {
  double? lat = 20.17,
  double? lng = -98.05,
  double? km,
  String? phone,
}) => Store(
  id: id,
  name: 'Librería $id',
  address: 'Calle $id',
  phone: phone,
  lat: lat,
  lng: lng,
  distanceKm: km,
);

void main() {
  late _MockStoreRepository repo;
  setUp(() => repo = _MockStoreRepository());

  void answer(Future<List<Store>> Function() result) => when(
    () => repo.getStores(
      lat: any(named: 'lat'),
      lng: any(named: 'lng'),
    ),
  ).thenAnswer((_) => result());

  group('walkingMinutes', () {
    test('walks at 5 km/h and rounds to whole minutes', () {
      expect(walkingMinutes(0.85), 10);
      expect(walkingMinutes(2.5), 30);
    });

    test('is never less than one minute', () {
      expect(walkingMinutes(0), 1);
      expect(walkingMinutes(0.01), 1);
    });
  });

  group('distanceToStore', () {
    test('prefers the distance given by the API', () {
      expect(distanceToStore(store('a', km: 0.85), _user), 0.85);
      expect(distanceToStore(store('a', km: 0.85), null), 0.85);
    });

    test('is computed on the phone when the API gave none', () {
      final north = store('a', lat: 20.18);

      expect(distanceToStore(north, _user), closeTo(1.11, 0.01));
    });

    test('is unknown without the position or the coordinates', () {
      expect(distanceToStore(store('a'), null), isNull);
      expect(distanceToStore(store('a', lat: null), _user), isNull);
      expect(distanceToStore(store('a', lng: null), _user), isNull);
    });
  });

  group('controllers', () {
    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [
          storeRepositoryProvider.overrideWithValue(repo),
          userPositionProvider.overrideWithValue(null),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('the map only draws stores that have coordinates', () async {
      answer(
        () async => [store('a'), store('b', lat: null, lng: null), store('c')],
      );
      final c = container();
      final sub = c.listen(mapStoresProvider, (_, _) {});
      addTearDown(sub.close);

      await c.read(storesListProvider.future);

      expect(c.read(mapStoresProvider).requireValue.map((s) => s.id), [
        'a',
        'c',
      ]);
    });

    test('a store is selected and deselected', () {
      final c = container();
      final sub = c.listen(selectedStoreIdProvider, (_, _) {});
      addTearDown(sub.close);

      expect(c.read(selectedStoreIdProvider), isNull);
      c.read(selectedStoreIdProvider.notifier).select('a');
      expect(c.read(selectedStoreIdProvider), 'a');
      c.read(selectedStoreIdProvider.notifier).select(null);
      expect(c.read(selectedStoreIdProvider), isNull);
    });
  });

  group('StoresMapPage', () {
    // The real GoogleMap needs a platform view: a column of pins stands in.
    Widget fakeMap(
      List<Store> stores,
      GeoPoint? user,
      String? selectedId,
      ValueChanged<String?> onSelect,
    ) => Column(
      children: [
        for (final s in stores)
          TextButton(
            onPressed: () => onSelect(s.id),
            child: Text('pin ${s.id}'),
          ),
      ],
    );

    GoRouter router() => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => StoresMapPage(mapBuilder: fakeMap),
        ),
        GoRoute(
          path: AppRoutes.storeDetail,
          builder: (_, state) => Text('detalle ${state.pathParameters['id']}'),
        ),
      ],
    );

    Future<void> pump(WidgetTester tester, {GeoPoint? user}) =>
        tester.pumpWidget(
          ProviderScope(
            overrides: [
              storeRepositoryProvider.overrideWithValue(repo),
              userPositionProvider.overrideWithValue(user),
            ],
            child: MaterialApp.router(routerConfig: router()),
          ),
        );

    testWidgets('shows a pin per store with coordinates', (tester) async {
      answer(() async => [store('a'), store('b', lat: null, lng: null)]);
      await pump(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('pin a'), findsOneWidget);
      expect(find.text('pin b'), findsNothing);
      expect(find.text('Librería a'), findsNothing);
    });

    testWidgets('tapping a pin opens the quick card', (tester) async {
      answer(() async => [store('a', km: 0.85, phone: '776 762 0145')]);
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('pin a'));
      await tester.pumpAndSettle();

      expect(find.text('Librería a'), findsOneWidget);
      expect(find.text('Calle a'), findsOneWidget);
      expect(find.text('850 m · 10 min a pie'), findsOneWidget);
      expect(find.text('Llamar'), findsOneWidget);
      expect(find.text('Cómo llegar'), findsOneWidget);
    });

    testWidgets('the distance is computed from the position of the user', (
      tester,
    ) async {
      answer(() async => [store('a', lat: 20.18)]);
      await pump(tester, user: _user);
      await tester.pumpAndSettle();

      await tester.tap(find.text('pin a'));
      await tester.pumpAndSettle();

      expect(find.text('1.1 km · 13 min a pie'), findsOneWidget);
    });

    testWidgets('without distance the card shows no walking time', (
      tester,
    ) async {
      answer(() async => [store('a')]);
      await pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('pin a'));
      await tester.pumpAndSettle();

      expect(find.textContaining('min a pie'), findsNothing);
    });

    testWidgets('tapping the card header opens the store', (tester) async {
      answer(() async => [store('s1')]);
      await pump(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('pin s1'));
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
      expect(find.text('pin a'), findsOneWidget);
    });
  });
}
