import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_colors.dart';
import 'package:bookia_mobile/features/splash/presentation/controllers/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen 01: BOOKIA logo while the stored session is checked, then Inicio.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(splashControllerProvider, (_, next) {
      if (!next.isLoading) context.go(AppRoutes.home);
    });
    ref.watch(splashControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.5, -0.6),
            radius: 1.3,
            colors: [AppColors.primaryDark, AppColors.espresso],
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 3),
                const _LogoTile(),
                const SizedBox(height: 32),
                Text.rich(
                  const TextSpan(
                    text: 'BOOK',
                    children: [
                      TextSpan(
                        text: 'IA',
                        style: TextStyle(color: AppColors.gold),
                      ),
                    ],
                  ),
                  style: text.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Libros de Huauchinango en tu mano',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const Spacer(flex: 2),
                const SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.gold,
                    semanticsLabel: 'Revisando tu sesión',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Huauchinango, Puebla',
                  style: text.bodyMedium?.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gold, AppColors.primary],
        ),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 24)],
      ),
      child: const Icon(
        Icons.menu_book_outlined,
        color: Colors.white,
        size: 52,
        semanticLabel: 'BOOKIA',
      ),
    );
  }
}
