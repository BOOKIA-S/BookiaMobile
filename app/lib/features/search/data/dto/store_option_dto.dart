/// The fields of a `GET /stores` item that the filters sheet needs.
class StoreOptionDto {
  const StoreOptionDto({required this.id, required this.name});

  /// Factory (PAT-05).
  factory StoreOptionDto.fromJson(Map<String, dynamic> json) => StoreOptionDto(
    id: json['_id'] as String,
    name: json['name'] as String? ?? '',
  );

  final String id;
  final String name;
}
