import 'dart:async';

import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';
import 'package:bookia_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_test_helpers.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  FakeProfileRepository? repository,
  SessionStatus? session,
  Size size = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: profileOverrides(repository: repository),
  );
  addTearDown(container.dispose);
  container.read(currentSessionProvider.notifier).set(session ?? testSession());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ProfilePage()),
    ),
  );
  return container;
}

void main() {
  testWidgets('shows loading, then the account', (tester) async {
    final pending = Completer<ProfileUser>();
    final repository = FakeProfileRepository()..onMe = () => pending.future;
    await _pump(tester, repository: repository);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(testProfileUser());
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsWidgets);
    expect(find.text('Editar nombre'), findsOneWidget);
  });

  testWidgets('handles optional account data without inventing values', (
    tester,
  ) async {
    final repository = FakeProfileRepository(
      user: const ProfileUser(
        id: 'u1',
        email: 'ana@bookia.mx',
        name: 'Ana',
        role: 'reader',
        storeId: null,
        mustChangePassword: false,
        createdAt: null,
      ),
    );
    await _pump(tester, repository: repository);
    await tester.pumpAndSettle();
    expect(find.textContaining('Fecha no disponible'), findsOneWidget);
    expect(find.text('Lector'), findsOneWidget);
  });

  testWidgets('a retry loads the account after an error', (tester) async {
    var calls = 0;
    final repository = FakeProfileRepository();
    repository.onMe = () async {
      calls++;
      if (calls == 1) throw const NetworkFailure();
      return testProfileUser();
    };
    await _pump(tester, repository: repository);
    await tester.pumpAndSettle();
    expect(find.text(const NetworkFailure().message), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsWidgets);
    expect(calls, 2);
  });

  testWidgets('a forced password change blocks activity and shows a banner', (
    tester,
  ) async {
    final repository = FakeProfileRepository(
      user: testProfileUser(mustChangePassword: true),
    );
    await _pump(tester, repository: repository);
    await tester.pumpAndSettle();
    expect(find.text('Debes cambiar tu contraseña'), findsOneWidget);
    expect(find.text('Mi actividad'), findsNothing);
    expect(find.text('Cambiar contraseña'), findsWidgets);
  });

  testWidgets('a store owner sees the panel and no reader activity', (
    tester,
  ) async {
    final repository = FakeProfileRepository(
      user: testProfileUser(
        role: 'store_owner',
        storeId: 's1',
        email: 'tienda@bookia.mx',
      ),
    );
    await _pump(tester, repository: repository);
    await tester.pumpAndSettle();
    expect(find.text('Encargado de librería'), findsOneWidget);
    expect(find.text('Panel de tienda'), findsOneWidget);
    expect(find.text('Mi actividad'), findsNothing);
  });

  testWidgets('an expired session offers login and hides private data', (
    tester,
  ) async {
    final repository = FakeProfileRepository()
      ..onMe = () => Future.error(const UnauthorizedFailure());
    await _pump(tester, repository: repository);
    await tester.pumpAndSettle();
    expect(find.text('Inicia sesión para continuar.'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('ana@bookia.mx'), findsNothing);
  });

  testWidgets('renders at 320x640 without overflow', (tester) async {
    await _pump(tester, size: const Size(320, 640));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Editar nombre'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
