import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/features/profile/presentation/pages/change_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_test_helpers.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required String role,
  required bool forced,
  FakeProfileRepository? repository,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: profileOverrides(repository: repository),
  );
  addTearDown(container.dispose);
  container
      .read(currentSessionProvider.notifier)
      .set(testSession(role: role, mustChangePassword: forced));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ChangePasswordPage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('validates empty fields and the confirmation', (tester) async {
    await _pump(tester, role: 'reader', forced: false);
    await tester.tap(find.widgetWithText(FilledButton, 'Cambiar contraseña'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu contraseña actual'), findsOneWidget);
    expect(find.text('Debe tener entre 8 y 200 caracteres'), findsOneWidget);
  });

  testWidgets('rejects a confirmation that does not match', (tester) async {
    await _pump(tester, role: 'reader', forced: false);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña actual'),
      'oldpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      'newpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repite la contraseña nueva'),
      'newpass2',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Cambiar contraseña'));
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });

  testWidgets('maps a wrong current password to Spanish', (tester) async {
    final repository = FakeProfileRepository()
      ..onChangePassword = (_, _) => Future.error(
        const ValidationFailure('Current password is incorrect'),
      );
    await _pump(tester, role: 'reader', forced: false, repository: repository);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña actual'),
      'wrongpass',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      'newpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repite la contraseña nueva'),
      'newpass1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Cambiar contraseña'));
    await tester.pumpAndSettle();
    expect(find.text('La contraseña actual es incorrecta.'), findsOneWidget);
  });

  testWidgets('a forced staff change offers the store panel', (tester) async {
    final repository = FakeProfileRepository(
      user: testProfileUser(role: 'store_owner', mustChangePassword: false),
    );
    final container = await _pump(
      tester,
      role: 'store_owner',
      forced: true,
      repository: repository,
    );
    expect(
      find.textContaining('necesita una contraseña nueva'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña actual'),
      'oldpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      'newpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repite la contraseña nueva'),
      'newpass1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Cambiar contraseña'));
    await tester.pumpAndSettle();

    expect(repository.passwordCalls, 1);
    expect(find.text('Contraseña actualizada'), findsOneWidget);
    expect(find.text('Ir al panel de tienda'), findsOneWidget);
    expect(
      (container.read(currentSessionProvider) as dynamic).mustChangePassword,
      isFalse,
    );
  });

  testWidgets('shows the rate limit in Spanish', (tester) async {
    final repository = FakeProfileRepository()
      ..onChangePassword = (_, _) => Future.error(const RateLimitFailure());
    await _pump(tester, role: 'reader', forced: false, repository: repository);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña actual'),
      'secretcurrent1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      'secretnew123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repite la contraseña nueva'),
      'secretnew123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Cambiar contraseña'));
    await tester.pumpAndSettle();
    expect(
      find.text('Demasiados intentos. Espera unos minutos.'),
      findsOneWidget,
    );
  });

  testWidgets('does not submit twice while the request is pending', (
    tester,
  ) async {
    final repository = FakeProfileRepository()
      ..onChangePassword = (_, _) => Future.delayed(
        const Duration(milliseconds: 300),
        () => testProfileUser(),
      );
    await _pump(tester, role: 'reader', forced: false, repository: repository);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña actual'),
      'oldpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      'newpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repite la contraseña nueva'),
      'newpass1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Cambiar contraseña'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardando…'))
          .onPressed,
      isNull,
    );
    await tester.pumpAndSettle();
    expect(repository.passwordCalls, 1);
  });
}
