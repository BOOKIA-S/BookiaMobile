import 'dart:math' as math;

/// Walking speed behind the "N min a pie" label, in km/h.
const walkingSpeedKmh = 5.0;

/// Minutes to walk [km] in a straight line; never less than 1.
int walkingMinutes(double km) =>
    math.max(1, (km / walkingSpeedKmh * 60).round());
