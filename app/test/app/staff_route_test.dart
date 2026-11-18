import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:bookia_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:bookia_mobile/features/auth/presentation/providers.dart';
import 'package:bookia_mobile/features/staff/domain/entities/staff_profile.dart';
import 'package:bookia_mobile/features/staff/domain/repositories/staff_repository.dart';
import 'package:bookia_mobile/features/staff/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../features/auth/auth_test_helpers.dart';
import '../helpers/fakes.dart';

class _MockStaffRepository extends Mock implements StaffRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockStaffRepository staff;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    staff = _MockStaffRepository();
    when(() => staff.getProfile()).thenAnswer(
      (_) async => const StaffProfile(
        name: 'Karol',
        role: 'admin',
        mustChangePassword: false,
      ),
    );
    when(() => staff.listReservations()).thenAnswer((_) async => const []);
  });

  test('only store owners and admins are staff', () {
    expect(AppRoutes.isStaffRole('store_owner'), isTrue);
    expect(AppRoutes.isStaffRole('admin'), isTrue);
    expect(AppRoutes.isStaffRole('reader'), isFalse);
    expect(AppRoutes.isStaffRole(''), isFalse);
  });

  Future<GoRouter> pumpGuarded(
    WidgetTester tester, {
    required SessionStatus session,
  }) async {
    final notifier = ValueNotifier<SessionStatus>(session);
    addTearDown(notifier.dispose);
    final container = ProviderContainer(
      overrides: [
        ...offlineOverrides(),
        staffRepositoryProvider.overrideWithValue(staff),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentSessionProvider.notifier).set(session);
    final router = createRouter(
      initialLocation: AppRoutes.staff,
      session: () => notifier.value,
      refreshListenable: notifier,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('a guest is sent to login', (tester) async {
    final router = await pumpGuarded(tester, session: const GuestSession());

    expect(router.state.uri.path, AppRoutes.auth);
  });

  testWidgets('a reader is sent home', (tester) async {
    final router = await pumpGuarded(
      tester,
      session: const SignedInSession(name: 'Ana', role: 'reader'),
    );

    expect(router.state.uri.path, AppRoutes.home);
  });

  for (final role in ['store_owner', 'admin']) {
    testWidgets('a $role reaches the panel', (tester) async {
      final router = await pumpGuarded(
        tester,
        session: SignedInSession(name: 'Karol', role: role),
      );

      expect(router.state.uri.path, AppRoutes.staff);
      expect(find.text('Panel de tienda'), findsOneWidget);
    });
  }

  AuthSession sessionOf(String role) => AuthSession(
    user: AuthUser(
      id: 'u1',
      email: 'a@b.mx',
      name: 'Karol',
      role: role,
      storeId: null,
      mustChangePassword: false,
      createdAt: DateTime.utc(2026, 11, 9),
    ),
    token: 'secret',
    expiresInSeconds: 60,
  );

  Future<void> logIn(WidgetTester tester, String role) async {
    final auth = FakeAuthRepository()..next = Future.value(sessionOf(role));
    final router = createRouter(initialLocation: AppRoutes.auth);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...offlineOverrides(),
          authRepositoryProvider.overrideWithValue(auth),
          staffRepositoryProvider.overrideWithValue(staff),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      'a@b.mx',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
  }

  testWidgets('signing in as staff opens the panel', (tester) async {
    await logIn(tester, 'store_owner');

    expect(find.text('Panel de tienda'), findsOneWidget);
  });

  testWidgets('signing in as a reader does not open the panel', (tester) async {
    await logIn(tester, 'reader');

    expect(find.text('Panel de tienda'), findsNothing);
  });
}
