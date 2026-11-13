import 'package:bookia_mobile/features/stores/data/dto/store_dto.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';

/// Adapter (PAT-07): API DTO to domain entity.
extension StoreMapper on StoreDto {
  Store toEntity() => Store(
    id: id,
    name: name,
    address: address,
    phone: phone,
    schedule: schedule,
    mapsUrl: mapsUrl,
    lat: lat,
    lng: lng,
    distanceKm: distanceKm,
  );
}
