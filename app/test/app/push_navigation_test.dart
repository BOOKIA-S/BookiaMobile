import 'package:bookia_mobile/app/push_navigation.dart';
import 'package:bookia_mobile/core/notifications/disabled_push_service.dart';
import 'package:bookia_mobile/core/notifications/push_message.dart';
import 'package:bookia_mobile/core/notifications/push_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../features/notifications/fake_push_service.dart';

const _id = '65a1b2c3d4e5f6a7b8c9d0e1';
const _bookPush = PushMessage(
  title: '¡Ya llegó!',
  body: 'Rayuela volvió a estar disponible',
  data: {'book_id': _id},
);

GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    for (final path in [
      '/splash',
      '/onboarding/location',
      '/home',
      '/reservations',
      '/books/:id',
      '/reservation/:id',
    ])
      GoRoute(
        path: path,
        builder: (_, state) => Scaffold(body: Text('at ${state.uri.path}')),
      ),
  ],
);

void main() {
  late FakePushService push;

  setUp(() {
    push = FakePushService();
    addTearDown(push.close);
  });

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String initial = '/home',
    PushService? service,
  }) async {
    final router = _router(initial);
    final messenger = GlobalKey<ScaffoldMessengerState>();
    final navigation = PushNavigation(
      push: service ?? push,
      router: router,
      messenger: messenger,
    );
    addTearDown(navigation.dispose);
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, scaffoldMessengerKey: messenger),
    );
    await navigation.start();
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('a tapped notification opens its book', (tester) async {
    await pumpApp(tester);

    push.opened.add(_bookPush);
    await tester.pumpAndSettle();

    expect(find.text('at /books/$_id'), findsOneWidget);
  });

  testWidgets('a reservation notification opens screen 11', (tester) async {
    await pumpApp(tester);

    push.opened.add(const PushMessage(data: {'reservation_id': _id}));
    await tester.pumpAndSettle();

    expect(find.text('at /reservation/$_id'), findsOneWidget);
  });

  testWidgets('the launch notification waits for splash and onboarding', (
    tester,
  ) async {
    push.initial = _bookPush;
    final router = await pumpApp(tester, initial: '/splash');
    expect(find.text('at /splash'), findsOneWidget);

    router.go('/onboarding/location');
    await tester.pumpAndSettle();
    expect(find.text('at /onboarding/location'), findsOneWidget);

    router.go('/home');
    await tester.pumpAndSettle();
    expect(find.text('at /books/$_id'), findsOneWidget);
  });

  testWidgets('in the foreground it shows a SnackBar with «Ver»', (
    tester,
  ) async {
    await pumpApp(tester);

    push.messages.add(_bookPush);
    await tester.pumpAndSettle();
    expect(find.textContaining('¡Ya llegó!'), findsOneWidget);
    expect(find.text('at /home'), findsOneWidget);

    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
    expect(find.text('at /books/$_id'), findsOneWidget);
  });

  testWidgets('a foreground message without link has no action', (
    tester,
  ) async {
    await pumpApp(tester);

    push.messages.add(const PushMessage(title: 'Aviso'));
    await tester.pumpAndSettle();

    expect(find.text('Aviso'), findsOneWidget);
    expect(find.text('Ver'), findsNothing);
  });

  testWidgets('messages without text or valid link are ignored', (
    tester,
  ) async {
    await pumpApp(tester);

    push.messages.add(const PushMessage(data: {'book_id': _id}));
    push.opened.add(const PushMessage(data: {'book_id': '/staff'}));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('at /home'), findsOneWidget);
  });

  testWidgets('does nothing when push is off', (tester) async {
    final router = await pumpApp(tester, service: const DisabledPushService());

    expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
  });
}
