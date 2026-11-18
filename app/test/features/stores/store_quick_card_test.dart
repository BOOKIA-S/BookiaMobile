import 'package:bookia_mobile/core/utils/external_launcher.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/presentation/widgets/store_quick_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLauncher extends Mock implements ExternalLauncher {}

Store store({String? phone = '776 762 0145'}) => Store(
  id: 's1',
  name: 'Librería Azalea',
  address: 'Av. Benito Juárez 112',
  phone: phone,
  lat: 20.17,
  lng: -98.05,
);

void main() {
  late _MockLauncher launcher;
  late int opened;

  setUpAll(() => registerFallbackValue(Uri()));
  setUp(() {
    launcher = _MockLauncher();
    opened = 0;
    when(() => launcher.open(any())).thenAnswer((_) async => true);
  });

  Future<void> pump(WidgetTester tester, Store s, {double? distance}) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [externalLauncherProvider.overrideWithValue(launcher)],
          child: MaterialApp(
            home: Scaffold(
              body: StoreQuickCard(
                store: s,
                distance: distance,
                onOpen: () => opened++,
              ),
            ),
          ),
        ),
      );

  testWidgets('shows the name and the address of the store', (tester) async {
    await pump(tester, store());

    expect(find.text('Librería Azalea'), findsOneWidget);
    expect(find.text('Av. Benito Juárez 112'), findsOneWidget);
  });

  testWidgets('under a kilometer the distance is in meters', (tester) async {
    await pump(tester, store(), distance: 0.85);

    expect(find.text('850 m · 10 min a pie'), findsOneWidget);
  });

  testWidgets('from a kilometer on the distance is in kilometers', (
    tester,
  ) async {
    await pump(tester, store(), distance: 2.5);

    expect(find.text('2.5 km · 30 min a pie'), findsOneWidget);
  });

  testWidgets('without distance there is no walking time', (tester) async {
    await pump(tester, store());

    expect(find.textContaining('min a pie'), findsNothing);
  });

  testWidgets('tapping the header opens the store', (tester) async {
    await pump(tester, store());

    await tester.tap(find.text('Librería Azalea'));

    expect(opened, 1);
  });

  testWidgets('Llamar and Cómo llegar do not open the store', (tester) async {
    await pump(tester, store());

    await tester.tap(find.text('Llamar'));
    await tester.pump();
    await tester.tap(find.text('Cómo llegar'));
    await tester.pump();

    verify(() => launcher.open(any())).called(2);
    expect(opened, 0);
  });

  testWidgets('without a phone only Cómo llegar is offered', (tester) async {
    await pump(tester, store(phone: null));

    expect(find.text('Llamar'), findsNothing);
    expect(find.text('Cómo llegar'), findsOneWidget);
  });
}
