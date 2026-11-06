import 'package:bookia_mobile/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpRouter(WidgetTester tester, {String? at}) async {
    final router = createRouter(initialLocation: at ?? AppRoutes.home);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('bottom bar shows the five public tabs', (tester) async {
    await pumpRouter(tester);
    for (final label in ['Inicio', 'Buscar', 'Mapa', 'Reservas', 'Perfil']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('tapping a tab opens its page', (tester) async {
    await pumpRouter(tester);
    await tester.tap(find.text('Reservas'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mis reservas'), findsOneWidget);
  });

  testWidgets('a deep link selects the matching tab', (tester) async {
    await pumpRouter(tester, at: AppRoutes.map);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 2);
  });
}
