import 'package:bookia_mobile/features/profile/data/dto/profile_user_dto.dart';
import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';

extension ProfileUserMapper on ProfileUserDto {
  ProfileUser toDomain() => ProfileUser(
    id: id,
    email: email,
    name: name,
    role: role,
    storeId: storeId,
    mustChangePassword: mustChangePassword,
    createdAt: createdAt,
  );
}
