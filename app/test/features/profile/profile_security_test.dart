import 'package:bookia_mobile/app/di.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_test_helpers.dart';

void main() {
  testWidgets('a successful logout ends in the visitor state', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var calls = 0;
    late ProviderContainer container;
    container = ProviderContainer(
      overrides: [
        ...profileOverrides(),
        signOutProvider.overrideWithValue(() async {
          calls++;
          container
              .read(currentSessionProvider.notifier)
              .set(const GuestSession());
        }),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentSessionProvider.notifier).set(testSession());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(
      find.textContaining('Inicia sesión para ver tu perfil'),
      findsOneWidget,
    );
    expect(find.text('ana@bookia.mx'), findsNothing);
  });

  testWidgets('switching accounts reloads the profile', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeProfileRepository();
    final container = ProviderContainer(
      overrides: profileOverrides(repository: repository),
    );
    addTearDown(container.dispose);
    container.read(currentSessionProvider.notifier).set(testSession());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsWidgets);

    repository.user = testProfileUser(
      id: 'u2',
      email: 'beto@bookia.mx',
      name: 'Beto',
    );
    container
        .read(currentSessionProvider.notifier)
        .set(testSession(id: 'u2', email: 'beto@bookia.mx', name: 'Beto'));
    await tester.pumpAndSettle();

    expect(find.text('Beto'), findsWidgets);
    expect(find.text('beto@bookia.mx'), findsOneWidget);
    expect(find.text('ana@bookia.mx'), findsNothing);
  });
}
