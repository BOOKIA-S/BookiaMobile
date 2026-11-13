import 'package:bookia_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:bookia_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:bookia_mobile/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  String? action;
  int calls = 0;
  bool? staff;
  Future<AuthSession>? next;

  static final session = AuthSession(
    user: AuthUser(
      id: 'u1',
      email: 'a@b.mx',
      name: 'Ana',
      role: 'reader',
      storeId: null,
      mustChangePassword: false,
      createdAt: DateTime.utc(2026, 11, 9),
    ),
    token: 'secret',
    expiresInSeconds: 60,
  );

  @override
  Future<AuthSession> login(
    String email,
    String password, {
    bool staff = false,
  }) async {
    calls++;
    action = 'login';
    this.staff = staff;
    return next ?? session;
  }

  @override
  Future<AuthSession> register(
    String name,
    String email,
    String password,
  ) async {
    calls++;
    action = 'register';
    return next ?? session;
  }
}
