import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Quantity of copies of screen 10, from 1 to [max] (48 dp targets, COD-09).
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    required this.value,
    required this.max,
    required this.onIncrement,
    required this.onDecrement,
    this.enabled = true,
    super.key,
  });

  final int value;
  final int max;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          onPressed: enabled && value > 1 ? onDecrement : null,
          icon: const Icon(Icons.remove),
          tooltip: 'Quitar un ejemplar',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Semantics(
            label: '$value ejemplares',
            child: Text(
              '$value',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        IconButton.outlined(
          onPressed: enabled && value < max ? onIncrement : null,
          icon: const Icon(Icons.add),
          tooltip: 'Agregar un ejemplar',
        ),
      ],
    );
  }
}
