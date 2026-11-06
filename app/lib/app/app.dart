import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Root widget of BOOKIA Mobile.
///
/// The router (I2-03) is added in the next commit.
class BookiaApp extends StatelessWidget {
  const BookiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BOOKIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const Scaffold(body: Center(child: Text('BOOKIA'))),
    );
  }
}
