/// A store of `GET /stores` or `GET /stores/near` (`snake_case`, id in `_id`).
class StoreDto {
  const StoreDto({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.schedule,
    this.mapsUrl,
    this.lat,
    this.lng,
    this.distanceKm,
  });

  /// Factory (PAT-05).
  factory StoreDto.fromJson(Map<String, dynamic> json) => StoreDto(
    id: json['_id'] as String,
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String?,
    schedule: json['schedule'] as String?,
    mapsUrl: json['maps_url'] as String?,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
  );

  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? schedule;
  final String? mapsUrl;
  final double? lat;
  final double? lng;
  final double? distanceKm;
}
