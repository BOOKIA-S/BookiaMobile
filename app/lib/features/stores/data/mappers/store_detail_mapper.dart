import 'package:bookia_mobile/features/stores/data/dto/store_detail_dto.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';

/// Adapter (PAT-07): API DTO to domain entity.
extension StoreOfferMapper on StoreOfferDto {
  StoreOffer toEntity() => StoreOffer(
    id: id,
    bookId: bookId,
    title: title,
    author: author,
    price: price,
    stock: stock,
    isAvailable: isAvailable,
  );
}

extension StoreDetailMapper on StoreDetailDto {
  StoreDetail toEntity() => StoreDetail(
    store: Store(
      id: id,
      name: name,
      address: address,
      phone: phone,
      schedule: schedule,
      mapsUrl: mapsUrl,
      lat: lat,
      lng: lng,
    ),
    offers: offers.map((o) => o.toEntity()).toList(),
  );
}
