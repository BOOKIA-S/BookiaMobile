import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../dto/auth_session_dto.dart';

extension AuthSessionMapper on AuthSessionDto {
  AuthSession toDomain() => AuthSession(
    user: AuthUser(
      id: user['_id'] as String,
      email: user['email'] as String,
      name: user['name'] as String,
      role: user['role'] as String,
      storeId: user['store_id'] as String?,
      mustChangePassword: user['must_change_password'] as bool,
      createdAt: DateTime.parse(user['created_at'] as String),
    ),
    token: token,
    expiresInSeconds: expiresIn,
  );
}
