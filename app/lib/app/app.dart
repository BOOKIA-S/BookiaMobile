import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Root widget of BOOKIA Mobile.
class BookiaApp extends StatefulWidget {
  const BookiaApp({super.key});

  @override
  State<BookiaApp> createState() => _BookiaAppState();
}

class _BookiaAppState extends State<BookiaApp> {
  final GoRouter _router = createRouter();

  @override
  void dispose() {
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
