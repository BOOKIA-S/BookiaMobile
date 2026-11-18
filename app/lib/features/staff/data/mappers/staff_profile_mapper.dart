import 'package:bookia_mobile/features/staff/data/dto/staff_profile_dto.dart';
import 'package:bookia_mobile/features/staff/domain/entities/staff_profile.dart';

/// Adapter (PAT-07): API DTO to domain entity.
extension StaffProfileMapper on StaffProfileDto {
  StaffProfile toEntity() => StaffProfile(
    name: name,
    role: role,
    storeId: storeId,
    mustChangePassword: mustChangePassword,
  );
}
