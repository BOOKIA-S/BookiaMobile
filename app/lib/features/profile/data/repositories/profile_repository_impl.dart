import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:bookia_mobile/features/profile/data/dto/profile_user_dto.dart';
import 'package:bookia_mobile/features/profile/data/mappers/profile_user_mapper.dart';
import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';
import 'package:bookia_mobile/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ProfileRemoteDataSource _remote;
  final DateTime Function() _now;

  @override
  Future<ProfileUser> me() async => _parse(await _remote.me());

  @override
  Future<ProfileUser> updateName(String name) async =>
      _parse(await _remote.updateName(name));

  @override
  Future<ProfileUser> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => _parse(
    await _remote.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    ),
  );

  @override
  Future<int> activeReservationCount() async {
    try {
      final json = await _remote.reservationsMine();
      final items = json['items'];
      if (items is! List) {
        throw const FormatException('Invalid reservations response');
      }
      final now = _now().toUtc();
      var count = 0;
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final status = item['status'];
        final expiresAt = DateTime.tryParse(
          item['expires_at'] as String? ?? '',
        );
        if ((status == 'pendiente' || status == 'confirmada') &&
            expiresAt != null &&
            expiresAt.isAfter(now)) {
          count++;
        }
      }
      return count;
    } on FormatException {
      throw const ServerFailure();
    } on TypeError {
      throw const ServerFailure();
    }
  }

  static ProfileUser _parse(Map<String, dynamic> json) {
    try {
      return ProfileUserDto.fromJson(json).toDomain();
    } on FormatException {
      throw const ServerFailure();
    } on TypeError {
      throw const ServerFailure();
    }
  }
}
