import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:bookia_mobile/features/auth/data/dto/auth_session_dto.dart';
import 'package:bookia_mobile/features/auth/data/mappers/auth_session_mapper.dart';
import 'package:bookia_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:bookia_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this.remote);

  final AuthRemoteDataSource remote;

  @override
  Future<AuthSession> login(
    String email,
    String password, {
    bool staff = false,
  }) async => _session(await remote.login(email, password, staff: staff));

  @override
  Future<AuthSession> register(
    String name,
    String email,
    String password,
  ) async => _session(await remote.register(name, email, password));

  static AuthSession _session(Map<String, dynamic> json) {
    try {
      return AuthSessionDto.fromJson(json).toDomain();
    } on FormatException {
      throw const ServerFailure();
    } on TypeError {
      throw const ServerFailure();
    }
  }
}
