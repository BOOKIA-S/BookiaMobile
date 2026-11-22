import 'package:bookia_mobile/features/search/data/models/cached_search_model.dart';
import 'package:hive_ce/hive.dart';

/// Adapter (PAT-07): writes [CachedSearchModel] to Hive and reads it back.
/// Written by hand so the project needs no code generation.
class CachedSearchAdapter extends TypeAdapter<CachedSearchModel> {
  @override
  final int typeId = 1;

  @override
  CachedSearchModel read(BinaryReader reader) {
    final m = reader.readMap();
    return CachedSearchModel(
      key: m['key'] as String,
      q: m['q'] as String?,
      genre: m['genre'] as String?,
      storeId: m['store_id'] as String?,
      minPrice: (m['min_price'] as num?)?.toDouble(),
      maxPrice: (m['max_price'] as num?)?.toDouble(),
      count: (m['count'] as num?)?.toInt() ?? 1,
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        (m['saved_at'] as num?)?.toInt() ?? 0,
      ),
      books: [
        for (final b in (m['books'] as List?) ?? const <Object?>[])
          if (b is Map) b.cast<String, Object?>(),
      ],
    );
  }

  @override
  void write(BinaryWriter writer, CachedSearchModel obj) => writer.writeMap({
    'key': obj.key,
    'q': obj.q,
    'genre': obj.genre,
    'store_id': obj.storeId,
    'min_price': obj.minPrice,
    'max_price': obj.maxPrice,
    'count': obj.count,
    'saved_at': obj.savedAt.millisecondsSinceEpoch,
    'books': obj.books,
  });
}
