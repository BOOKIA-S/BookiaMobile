import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/features/reservations/presentation/formatters.dart';
import 'package:bookia_mobile/features/staff/domain/entities/store_panel.dart';
import 'package:flutter/material.dart';

/// The four numbers on top of screen 16. The catalog ones need a store, so
/// an admin only sees the reservation ones.
class PanelIndicators extends StatelessWidget {
  const PanelIndicators({required this.panel, required this.now, super.key});

  final StorePanel panel;

  /// Moment that decides which month "Apartado del mes" adds up.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final titles = panel.catalogTitles;
    final soldOut = panel.soldOutOffers;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _Indicator('Por confirmar', '${panel.pending.length}'),
        if (titles != null) _Indicator('Títulos en catálogo', '$titles'),
        if (soldOut != null) _Indicator('Ofertas agotadas', '$soldOut'),
        _Indicator('Apartado del mes', mxn.format(panel.monthAmount(now))),
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 160,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: text.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
