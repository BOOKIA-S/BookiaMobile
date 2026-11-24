import 'package:bookia_mobile/features/search/data/models/cached_search_adapter.dart';
import 'package:bookia_mobile/features/search/data/models/cached_search_model.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Local store of the last searches (I2-10).
abstract interface class SearchCacheDataSource {
  CachedSearchModel? read(String key);

  /// Saves [entry] and keeps only the 20 most recent searches.
  Future<void> write(CachedSearchModel entry);

  List<CachedSearchModel> all();
}

const _maxEntries = 20;

List<CachedSearchModel> _oldestFirst(Iterable<CachedSearchModel> entries) =>
    entries.toList()..sort((a, b) => a.savedAt.compareTo(b.savedAt));

/// Hive box `search_cache`, opened once in main.
class HiveSearchCacheDataSource implements SearchCacheDataSource {
  const HiveSearchCacheDataSource(this._box);

  static const boxName = 'search_cache';
  final Box<CachedSearchModel> _box;

  /// Opens the box for the app. Call after `Hive.initFlutter()`.
  static Future<HiveSearchCacheDataSource> open() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CachedSearchAdapter());
    }
    return HiveSearchCacheDataSource(
      await Hive.openBox<CachedSearchModel>(boxName),
    );
  }

  @override
  CachedSearchModel? read(String key) => _box.get(key);

  @override
  Future<void> write(CachedSearchModel entry) async {
    await _box.put(entry.key, entry);
    final extra = _box.length - _maxEntries;
    if (extra > 0) {
      await _box.deleteAll(
        _oldestFirst(_box.values).take(extra).map((e) => e.key),
      );
    }
  }

  @override
  List<CachedSearchModel> all() => _box.values.toList();
}

/// Keeps the searches only while the app runs: the default when Hive was
/// not opened (widget tests).
class MemorySearchCacheDataSource implements SearchCacheDataSource {
  final _entries = <String, CachedSearchModel>{};

  @override
  CachedSearchModel? read(String key) => _entries[key];

  @override
  Future<void> write(CachedSearchModel entry) async {
    _entries[entry.key] = entry;
    final extra = _entries.length - _maxEntries;
    if (extra > 0) {
      for (final old in _oldestFirst(_entries.values).take(extra)) {
        _entries.remove(old.key);
      }
    }
  }

  @override
  List<CachedSearchModel> all() => _entries.values.toList();
}
