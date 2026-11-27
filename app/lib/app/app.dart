import 'dart:async';

import 'package:bookia_mobile/app/push_navigation.dart';
import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:bookia_mobile/core/notifications/push_providers.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/notifications/presentation/controllers/push_registration_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Root widget of BOOKIA Mobile.
class BookiaApp extends ConsumerStatefulWidget {
  const BookiaApp({super.key});

  @override
  ConsumerState<BookiaApp> createState() => _BookiaAppState();
}

class _BookiaAppState extends ConsumerState<BookiaApp> {
  late final ValueNotifier<SessionStatus> _session;
  late final GoRouter _router;
  late final PushNavigation _pushNavigation;
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  ProviderSubscription<SessionStatus>? _sessionListener;

  @override
  void initState() {
    super.initState();
    _session = ValueNotifier(ref.read(currentSessionProvider));
    _router = createRouter(
      initialLocation: AppRoutes.splash,
      session: () => _session.value,
      refreshListenable: _session,
    );
    _sessionListener = ref.listenManual(currentSessionProvider, (_, next) {
      _session.value = next;
    });
    // Screen 13: links the FCM token to the account after each sign-in.
    ref.read(pushRegistrationProvider);
    // Screen 13: tapping a push opens its reservation or book.
    _pushNavigation = PushNavigation(
      push: ref.read(pushServiceProvider),
      router: _router,
      messenger: _messenger,
    );
    unawaited(_pushNavigation.start());
  }

  @override
  void dispose() {
    _pushNavigation.dispose();
    _sessionListener?.close();
    _session.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BOOKIA',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messenger,
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}
