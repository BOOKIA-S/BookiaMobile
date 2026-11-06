import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = AppTheme.light();

  test('uses Material 3 with the BOOKIA palette', () {
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.error, AppColors.error);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });

  test('buttons meet the 48 dp minimum touch target (COD-09)', () {
    final size = theme.filledButtonTheme.style!.minimumSize!.resolve({});
    expect(size!.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
  });

  test('titles use the serif family and body text does not', () {
    expect(theme.textTheme.headlineSmall!.fontFamily, 'serif');
    expect(theme.textTheme.bodyLarge!.fontFamily, isNot('serif'));
  });
}
