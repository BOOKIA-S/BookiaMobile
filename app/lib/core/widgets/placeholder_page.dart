import 'package:flutter/material.dart';

/// Temporary page for a tab whose screen is not built yet.
/// Each owner replaces it with the real page from their feature.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Próximamente',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
