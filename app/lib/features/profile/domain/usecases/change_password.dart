import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';
import 'package:bookia_mobile/features/profile/domain/repositories/profile_repository.dart';

/// Validation shared by the form and the use case. The server remains the
/// authority on the current password and on the session.
class ChangePassword {
  const ChangePassword(this._repository);

  static const minLength = 8;
  static const maxLength = 200;

  final ProfileRepository _repository;

  Future<ProfileUser> call({
    required String currentPassword,
    required String newPassword,
  }) {
    if (currentPassword.isEmpty) {
      throw const ValidationFailure('Escribe tu contraseña actual.');
    }
    if (newPassword.length < minLength || newPassword.length > maxLength) {
      throw const ValidationFailure(
        'La contraseña nueva debe tener entre 8 y 200 caracteres.',
      );
    }
    if (newPassword == currentPassword) {
      throw const ValidationFailure(
        'La contraseña nueva debe ser distinta de la actual.',
      );
    }
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
