import 'package:bookia_mobile/features/splash/domain/entities/session_status.dart';
import 'package:bookia_mobile/features/splash/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) of screen 01: checks the stored session once and
/// publishes the result in [currentSessionProvider].
class SplashController extends AsyncNotifier<SessionStatus> {
  @override
  Future<SessionStatus> build() async {
    final status = await ref.read(checkStoredSessionProvider).call();
    ref.read(currentSessionProvider.notifier).set(status);
    return status;
  }
}

final splashControllerProvider =
    AsyncNotifierProvider.autoDispose<SplashController, SessionStatus>(
      SplashController.new,
    );
