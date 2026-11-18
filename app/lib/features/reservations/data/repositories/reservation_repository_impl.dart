import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/reservations/data/datasources/reservation_remote_data_source.dart';
import 'package:bookia_mobile/features/reservations/data/dto/reservation_dto.dart';
import 'package:bookia_mobile/features/reservations/data/mappers/reservation_mapper.dart';
import 'package:bookia_mobile/features/reservations/domain/entities/reservation.dart';
import 'package:bookia_mobile/features/reservations/domain/repositories/reservation_repository.dart';

/// Repository (PAT-01): turns API payloads into domain entities and keeps the
/// user-facing messages in Spanish.
class ReservationRepositoryImpl implements ReservationRepository {
  const ReservationRepositoryImpl(this._remote);

  final ReservationRemoteDataSource _remote;

  @override
  Future<Reservation> create({
    required String offerId,
    required int quantity,
  }) async => _parse(
    () async => ReservationDto.fromJson(
      await _remote.create(offerId: offerId, quantity: quantity),
    ).toEntity(),
  );

  @override
  Future<List<Reservation>> listMine() async => _parse(
    () async => [
      for (final item in await _remote.listMine())
        ReservationDto.fromJson(item).toEntity(),
    ],
  );

  /// Any error leaves data/ as a Failure (ARQ-05); the API messages are in
  /// English, so the create errors are translated here.
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

  static Failure _translate(Failure failure) {
    if (failure is ValidationFailure) {
      // shortcut: the API has no error code for the 10-active limit, so it is
      // recognized by its message. Upgrade when the contract adds a code.
      final message = failure.message.toLowerCase();
      if (message.contains('active reservations')) {
        return const ValidationFailure(
          'Ya tienes 10 reservas activas. Espera a que venza alguna.',
        );
      }
      if (message.contains('quantity')) {
        return const ValidationFailure('Elige de 1 a 5 ejemplares.');
      }
      if (message.contains('offer')) {
        return const ValidationFailure('Esta oferta ya no es válida.');
      }
      return const ValidationFailure(
        'No pudimos crear la reserva. Revisa los datos.',
      );
    }
    if (failure is ConflictFailure) {
      return const ConflictFailure('Ya no hay suficientes ejemplares.');
    }
    if (failure is NotFoundFailure) {
      return const NotFoundFailure('Esta oferta ya no está disponible.');
    }
    return failure;
  }
}
