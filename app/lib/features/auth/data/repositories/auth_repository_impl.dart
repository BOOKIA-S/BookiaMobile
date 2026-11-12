import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../dto/auth_session_dto.dart';
import '../mappers/auth_session_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this.remote);

  final AuthRemoteDataSource remote;

  @override
  Future<AuthSession> login(
    String email,
    String password, {
    bool staff = false,
  }) async =>
      AuthSessionDto.fromJson(await remote.login(email, password, staff: staff))
          .toDomain();

  @override
  Future<AuthSession> register(
    String name,
    String email,
    String password,
  ) async =>
      AuthSessionDto.fromJson(await remote.register(name, email, password))
          .toDomain();
}
