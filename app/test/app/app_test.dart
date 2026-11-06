import 'package:bookia_mobile/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BookiaApp opens on the Inicio tab', (tester) async {
    await tester.pumpWidget(const BookiaApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Inicio'), findsOneWidget);
  });
}
