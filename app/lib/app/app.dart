import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
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
  }

  @override
  void dispose() {
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
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}
