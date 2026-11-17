import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/features/scanner/presentation/pages/scanner_page.dart';
import 'package:bookia_mobile/features/scanner/presentation/widgets/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

/// Stands in for the camera: tapping it "reads" [code].
Override fakeCamera(String code) => cameraViewProvider.overrideWithValue(
  (onCode) => Center(
    child: TextButton(
      onPressed: () => onCode(code),
      child: const Text('simular lectura'),
    ),
  ),
);

void main() {
  testWidgets('shows the hint and the code the camera reads', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fakeCamera('9780306406157')],
        child: const MaterialApp(home: ScannerPage()),
      ),
    );
    expect(
      find.text('Apunta al código de barras de la contraportada'),
      findsOneWidget,
    );

    await tester.tap(find.text('simular lectura'));
    await tester.pump();
    expect(find.text('Código leído: 9780306406157'), findsOneWidget);
  });

  testWidgets('the scan button on 03 Inicio opens screen 06', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...offlineOverrides(), fakeCamera('0')],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Escanear ISBN'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Escanear ISBN'), findsOneWidget);
  });
}
