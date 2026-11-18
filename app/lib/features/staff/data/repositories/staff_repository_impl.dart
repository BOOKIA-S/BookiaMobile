import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/data/dto/reservation_dto.dart';
import 'package:bookia_mobile/features/reservations/data/mappers/reservation_mapper.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/staff/data/datasources/staff_remote_data_source.dart';
import 'package:bookia_mobile/features/staff/data/dto/staff_profile_dto.dart';
import 'package:bookia_mobile/features/staff/data/mappers/staff_profile_mapper.dart';
import 'package:bookia_mobile/features/staff/domain/entities/staff_profile.dart';
import 'package:bookia_mobile/features/staff/domain/repositories/staff_repository.dart';

/// Repository (PAT-01): turns API payloads into domain entities and keeps the
/// user-facing messages in Spanish.
class StaffRepositoryImpl implements StaffRepository {
  const StaffRepositoryImpl(this._remote);

  final StaffRemoteDataSource _remote;

  @override
  Future<StaffProfile> getProfile() async => _parse(
    () async => StaffProfileDto.fromJson(await _remote.me()).toEntity(),
  );

  @override
  Future<List<Reservation>> listReservations() async => _parse(
    () async => [
      for (final item in await _remote.manage())
        ReservationDto.fromJson(item).toEntity(),
    ],
  );

  @override
  Future<Reservation> confirm(String reservationId) =>
      _change(reservationId, 'confirmada');

  @override
  Future<Reservation> reject(String reservationId) =>
      _change(reservationId, 'cancelada');

  Future<Reservation> _change(String id, String status) => _parse(
    () async =>
        ReservationDto.fromJson(await _remote.setStatus(id, status)).toEntity(),
  );

  /// Any error leaves data/ as a Failure (ARQ-05); the API messages are in
  /// English, so the desk errors are translated here.
  static Future<T> _parse<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on Failure catch (failure) {
      throw _translate(failure);
    } on FormatException {
      throw const ServerFailure();
    } on TypeError {
      throw const ServerFailure();
    }
  }

  static Failure _translate(Failure failure) => switch (failure) {
    ConflictFailure() => const ConflictFailure(
      'Esta reserva ya cambió de estado. Actualiza la lista.',
    ),
    NotFoundFailure() => const NotFoundFailure(
      'Esta reserva ya no está disponible.',
    ),
    ValidationFailure() => const ValidationFailure(
      'No pudimos cambiar la reserva. Intenta de nuevo.',
    ),
    _ => failure,
  };
}
