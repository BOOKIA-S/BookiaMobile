/// A book saved by the signed-in reader (`GET /favorites`).
class FavoriteBook {
  const FavoriteBook({
    required this.id,
    required this.title,
    this.author = '',
    this.genre,
    this.publisher,
  });

  final String id;
  final String title;
  final String author;
  final String? genre;
  final String? publisher;
}
