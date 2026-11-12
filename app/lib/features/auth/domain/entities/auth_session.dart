import 'auth_user.dart';

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
