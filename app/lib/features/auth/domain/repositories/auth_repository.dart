import 'package:bookia_mobile/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login(
    String email,
    String password, {
    bool staff = false,
  });

  Future<AuthSession> register(String name, String email, String password);
}
