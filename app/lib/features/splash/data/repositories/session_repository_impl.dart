import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/core/storage/token_store.dart';
import 'package:bookia_mobile/features/splash/data/dto/me_dto.dart';
import 'package:bookia_mobile/features/splash/domain/entities/session_status.dart';
import 'package:bookia_mobile/features/splash/domain/repositories/session_repository.dart';

/// The Bearer header is added by the AuthInterceptor of I5-05.
class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  @override
  Future<bool> hasStoredToken() async {
    final token = await _tokens.read();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<SignedInSession> fetchCurrentUser() async {
    final json = await _api.get<Map<String, dynamic>>('/auth/me');
    final me = MeDto.fromJson(json);
    return SignedInSession(name: me.name, role: me.role);
  }

  @override
  Future<void> clearStoredToken() => _tokens.delete();
}
