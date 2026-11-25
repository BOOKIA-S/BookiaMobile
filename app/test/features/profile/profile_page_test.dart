import 'package:bookia_mobile/app/di.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_test_helpers.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required SessionStatus session,
  FakeProfileRepository? repository,
  FakeSignOut? signOut,
  int activeReservations = 0,
  int favorites = 0,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      ...profileOverrides(
        repository: repository,
        activeReservations: activeReservations,
        favorites: favorites,
      ),
      if (signOut != null) signOutProvider.overrideWithValue(signOut.call),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentSessionProvider.notifier).set(session);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ProfilePage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('a visitor is invited to sign in and sees no private data', (
    tester,
  ) async {
    await _pump(tester, session: const GuestSession());
    expect(
      find.textContaining('Inicia sesión para ver tu perfil'),
      findsOneWidget,
    );
    expect(find.text('ana@bookia.mx'), findsNothing);
  });

  testWidgets('shows the real account and its activity', (tester) async {
    final repository = FakeProfileRepository();
    await _pump(
      tester,
      session: testSession(),
      repository: repository,
      activeReservations: 2,
    );
    expect(find.text('Ana'), findsWidgets);
    expect(find.text('ana@bookia.mx'), findsOneWidget);
    expect(find.text('Lector'), findsOneWidget);
    expect(find.textContaining('Miembro desde'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('edits the name with the server response', (tester) async {
    final repository = FakeProfileRepository();
    repository.onUpdateName = (name) async {
      repository.user = testProfileUser(name: name);
      return repository.user;
    };
    await _pump(tester, session: testSession(), repository: repository);

    await tester.tap(find.text('Editar nombre'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      '  Ana María  ',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(repository.lastName, 'Ana María');
    expect(find.text('Ana María'), findsWidgets);
    expect(find.text('Nombre actualizado.'), findsOneWidget);
  });

  testWidgets('shows a network error and retries the profile', (tester) async {
    final repository = FakeProfileRepository()
      ..onMe = () => Future.error(const NetworkFailure());
    await _pump(tester, session: testSession(), repository: repository);

    expect(find.text(const NetworkFailure().message), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('a failed logout shows a safe state and retries', (tester) async {
    final signOut = FakeSignOut()..error = StateError('storage failed');
    await _pump(tester, session: testSession(), signOut: signOut);

    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No pudimos borrar el acceso guardado'),
      findsOneWidget,
    );
    expect(find.text('ana@bookia.mx'), findsNothing);
    expect(signOut.calls, 1);
  });
}
