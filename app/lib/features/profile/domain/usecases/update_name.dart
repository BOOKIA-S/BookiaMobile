import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';
import 'package:bookia_mobile/features/profile/domain/repositories/profile_repository.dart';

/// Validates the name locally, then sends only that field to the API.
class UpdateName {
  const UpdateName(this._repository);

  static const maxLength = 80;

  final ProfileRepository _repository;

  Future<ProfileUser> call(String name) {
    final clean = name.trim();
    if (clean.isEmpty) {
      throw const ValidationFailure('Escribe tu nombre.');
    }
    if (clean.length > maxLength) {
      throw const ValidationFailure(
        'El nombre debe tener 80 caracteres o menos.',
      );
    }
    return _repository.updateName(clean);
  }
}
