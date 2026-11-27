import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';
import 'package:bookia_mobile/features/profile/domain/repositories/profile_repository.dart';

/// Loads the authoritative account of the signed-in user.
class LoadProfile {
  const LoadProfile(this._repository);

  final ProfileRepository _repository;

  Future<ProfileUser> call() => _repository.me();
}
