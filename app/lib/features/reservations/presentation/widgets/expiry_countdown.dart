import 'dart:async';

import 'package:flutter/material.dart';

/// "Vence en 1 d 3 h", "Vence en 2 h 15 min", "Vence en 5 min" or "Vencida".
String remainingLabel(Duration left) {
  if (left <= Duration.zero) return 'Vencida';
  final days = left.inDays;
  final hours = left.inHours % 24;
  final minutes = left.inMinutes % 60;
  if (days > 0) return 'Vence en $days d $hours h';
  if (hours > 0) return 'Vence en $hours h $minutes min';
  return 'Vence en ${minutes < 1 ? 1 : minutes} min';
}

/// Time left until [expiresAt], refreshed every minute while on screen.
class ExpiryCountdown extends StatefulWidget {
  const ExpiryCountdown({
    required this.expiresAt,
    this.now = DateTime.now,
    super.key,
  });

  final DateTime expiresAt;

  /// Clock, replaceable in tests.
  final DateTime Function() now;

  @override
  State<ExpiryCountdown> createState() => _ExpiryCountdownState();
}

class _ExpiryCountdownState extends State<ExpiryCountdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.expiresAt.difference(widget.now());
    final soon = left < const Duration(hours: 6);
    return Text(
      remainingLabel(left),
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: soon ? Theme.of(context).colorScheme.error : null),
    );
  }
}
