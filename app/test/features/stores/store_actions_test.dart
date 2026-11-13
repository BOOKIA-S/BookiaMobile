import 'package:bookia_mobile/core/utils/external_launcher.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store_actions.dart';
import 'package:bookia_mobile/features/stores/presentation/widgets/store_actions_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLauncher extends Mock implements ExternalLauncher {}

Store store({
  String? phone = '776 762 0145',
  double? lat = 20.17,
  double? lng = -98.05,
}) => Store(
  id: 's1',
  name: 'Librería Azalea',
  address: 'Av. Benito Juárez 112',
  phone: phone,
  lat: lat,
  lng: lng,
);

void main() {
  group('StoreActions', () {
    test('callUri keeps only digits and a leading plus', () {
      expect(store().callUri, Uri.parse('tel:7767620145'));
      expect(
        store(phone: '(776) 762-0145').callUri,
        Uri.parse('tel:7767620145'),
      );
      expect(
        store(phone: '+52 776 762 0145').callUri,
        Uri.parse('tel:+527767620145'),
      );
    });

    test('callUri is null when there is no usable phone', () {
      expect(store(phone: null).callUri, isNull);
      expect(store(phone: '  ').callUri, isNull);
      expect(store(phone: 'sin teléfono').callUri, isNull);
    });

    test('directionsUri points at the coordinates when known', () {
      final uri = store().directionsUri;

      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters, {'api': '1', 'destination': '20.17,-98.05'});
    });

    test(
      'directionsUri falls back to the address without both coordinates',
      () {
        for (final s in [store(lat: null, lng: null), store(lng: null)]) {
          expect(
            s.directionsUri.queryParameters['destination'],
            'Av. Benito Juárez 112',
          );
        }
      },
    );
  });

  group('StoreActionsBar', () {
    late _MockLauncher launcher;
    setUpAll(() => registerFallbackValue(Uri()));
    setUp(() {
      launcher = _MockLauncher();
      when(() => launcher.open(any())).thenAnswer((_) async => true);
    });

    Future<void> pump(WidgetTester tester, Store s) => tester.pumpWidget(
      ProviderScope(
        overrides: [externalLauncherProvider.overrideWithValue(launcher)],
        child: MaterialApp(
          home: Scaffold(body: StoreActionsBar(store: s)),
        ),
      ),
    );

    testWidgets('Llamar opens the dialer with the phone', (tester) async {
      await pump(tester, store());

      await tester.tap(find.text('Llamar'));
      await tester.pump();

      verify(() => launcher.open(Uri.parse('tel:7767620145'))).called(1);
    });

    testWidgets('Cómo llegar opens the route to the store', (tester) async {
      await pump(tester, store());

      await tester.tap(find.text('Cómo llegar'));
      await tester.pump();

      verify(() => launcher.open(store().directionsUri)).called(1);
    });

    testWidgets('without a phone only Cómo llegar is offered', (tester) async {
      await pump(tester, store(phone: null));

      expect(find.text('Llamar'), findsNothing);
      expect(find.text('Cómo llegar'), findsOneWidget);
    });

    testWidgets('tells the user when no app can open the link', (tester) async {
      when(() => launcher.open(any())).thenAnswer((_) async => false);
      await pump(tester, store());

      await tester.tap(find.text('Llamar'));
      await tester.pump();

      expect(find.text('No pudimos abrir la aplicación.'), findsOneWidget);
    });
  });
}
