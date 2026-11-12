import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:flutter/material.dart';

/// One row of the store list: name, address and distance when known.
class StoreTile extends StatelessWidget {
  const StoreTile({required this.store, required this.onTap, super.key});

  final Store store;
  final VoidCallback onTap;

  /// "850 m" under one kilometer, "1.3 km" above.
  static String formatDistance(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    final distance = store.distanceKm;
    return ListTile(
      title: Text(store.name),
      subtitle: Text(store.address),
      trailing: distance == null ? null : Text(formatDistance(distance)),
      onTap: onTap,
    );
  }
}
