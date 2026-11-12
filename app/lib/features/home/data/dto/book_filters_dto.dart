/// Body of `GET /books/filters`: `{ genres: [], publishers: [] }`.
class BookFiltersDto {
  const BookFiltersDto({required this.genres, required this.publishers});

  /// Factory (PAT-05).
  factory BookFiltersDto.fromJson(Map<String, dynamic> json) => BookFiltersDto(
    genres: _strings(json['genres']),
    publishers: _strings(json['publishers']),
  );

  final List<String> genres;
  final List<String> publishers;

  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}
