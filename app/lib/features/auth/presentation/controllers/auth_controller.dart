import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:bookia_mobile/features/auth/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<AuthSession?>>(
      AuthController.new,
    );

class AuthController extends Notifier<AsyncValue<AuthSession?>> {
  AuthSession? _currentSession;
  AuthSession? get currentSession => _currentSession;

  @override
  AsyncValue<AuthSession?> build() => const AsyncData(null);

  Future<void> login(String email, String password, {bool staff = false}) =>
      _authenticate(
        () => ref
            .read(authRepositoryProvider)
            .login(email, password, staff: staff),
      );

  Future<void> register(String name, String email, String password) =>
      _authenticate(
        () => ref.read(authRepositoryProvider).register(name, email, password),
      );

  Future<void> _authenticate(Future<AuthSession> Function() request) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      final session = await request();
      await ref.read(tokenStorageProvider).saveToken(session.token);
      _currentSession = session;
      state = AsyncData(session);
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clearToken();
    _currentSession = null;
    state = const AsyncData(null);
  }

  void sessionExpired() {
    _currentSession = null;
    state = const AsyncData(null);
  }
}
