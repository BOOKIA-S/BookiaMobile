import 'package:flutter/material.dart';

/// Root widget of BOOKIA Mobile.
///
/// Theme (I2-02) and router (I2-03) are added in the next commits.
class BookiaApp extends StatelessWidget {
  const BookiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'BOOKIA',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('BOOKIA'))),
    );
  }
}
