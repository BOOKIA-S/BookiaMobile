import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Type scale. Mockups use a serif for titles and a sans for UI text.
/// Fonts are not bundled yet (Literata/Inter are OFL, outside LIC-01),
/// so titles use the platform serif and body text the platform sans.
abstract final class AppTypography {
  static const _serif = 'serif';
  static const _serifFallback = ['Georgia', 'Noto Serif'];

  static TextTheme textTheme() {
    TextStyle title(double size, FontWeight weight) => TextStyle(
      fontFamily: _serif,
      fontFamilyFallback: _serifFallback,
      fontSize: size,
      fontWeight: weight,
      height: 1.2,
      color: AppColors.textPrimary,
    );
    TextStyle body(double size, FontWeight weight, Color color) =>
        TextStyle(fontSize: size, fontWeight: weight, color: color);

    return TextTheme(
      displaySmall: title(32, FontWeight.w700),
      headlineMedium: title(28, FontWeight.w700),
      headlineSmall: title(24, FontWeight.w700),
      titleLarge: title(20, FontWeight.w700),
      titleMedium: body(17, FontWeight.w600, AppColors.textPrimary),
      titleSmall: body(15, FontWeight.w600, AppColors.textPrimary),
      bodyLarge: body(16, FontWeight.w400, AppColors.textPrimary),
      bodyMedium: body(14, FontWeight.w400, AppColors.textSecondary),
      bodySmall: body(12, FontWeight.w400, AppColors.textSecondary),
      labelLarge: body(15, FontWeight.w600, AppColors.primary),
      labelMedium: body(13, FontWeight.w500, AppColors.textPrimary),
      labelSmall: body(11, FontWeight.w600, AppColors.primary),
    );
  }
}
