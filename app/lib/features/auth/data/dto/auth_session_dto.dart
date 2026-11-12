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
    return AuthSessionDto(
      user: user,
      token: json['token'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }

  final Map<String, dynamic> user;
  final String token;
  final int expiresIn;
}
