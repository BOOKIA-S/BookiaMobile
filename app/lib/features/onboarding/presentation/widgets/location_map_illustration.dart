import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Drawn map of screen 02: streets, three stores and the user in the middle.
/// Decorative only, so it is hidden from screen readers.
class LocationMapIllustration extends StatelessWidget {
  const LocationMapIllustration({super.key});

  static const _pins = [
    Alignment(-0.6, -0.65),
    Alignment(0.55, 0.45),
    Alignment(-0.4, 0.68),
  ];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1.2,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: CustomPaint(
            painter: _StreetsPainter(),
            child: Stack(
              children: [
                for (final pin in _pins)
                  Align(
                    alignment: pin,
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 44,
                    ),
                  ),
                const Align(child: _UserDot()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.15),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF3B82F6),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
    );
  }
}

class _StreetsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sand, AppColors.surfaceTint],
        ).createShader(rect),
    );
    final street = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = size.width * 0.03;
    Offset at(double x, double y) => Offset(size.width * x, size.height * y);
    canvas
      ..drawLine(at(0, 0.3), at(1, 0.2), street)
      ..drawLine(at(0, 0.5), at(1, 0.5), street)
      ..drawLine(at(0, 0.71), at(1, 0.8), street)
      ..drawLine(at(0.27, 0), at(0.33, 1), street)
      ..drawLine(at(0.49, 0), at(0.5, 1), street)
      ..drawLine(at(0.69, 0), at(0.65, 1), street);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
