import 'package:bookia_mobile/features/auth/domain/entities/auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.token,
    required this.expiresInSeconds,
  });

  final AuthUser user;
  final String token;
  final int expiresInSeconds;
}
