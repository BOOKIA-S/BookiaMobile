import 'package:bookia_mobile/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BookiaApp starts and shows the BOOKIA title', (tester) async {
    await tester.pumpWidget(const BookiaApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('BOOKIA'), findsOneWidget);
  });
}
