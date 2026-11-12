class AuthSessionDto {
  const AuthSessionDto({
    required this.user,
    required this.token,
    required this.expiresIn,
  });

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Invalid session response');
    }
    final token = json['token'] as String;
    final expiresIn = json['expires_in'] as int;
    if (token.trim().isEmpty || expiresIn <= 0) {
      throw const FormatException('Invalid session response');
    }
    return AuthSessionDto(user: user, token: token, expiresIn: expiresIn);
  }

  final Map<String, dynamic> user;
  final String token;
  final int expiresIn;
}
