import 'dart:io';

import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/search/data/datasources/local/search_cache_data_source.dart';
import 'package:bookia_mobile/features/search/data/models/cached_search_adapter.dart';
import 'package:bookia_mobile/features/search/data/models/cached_search_model.dart';
import 'package:bookia_mobile/features/search/data/repositories/cached_search_repository.dart';
import 'package:bookia_mobile/features/search/domain/entities/book_summary.dart';
import 'package:bookia_mobile/features/search/domain/entities/search_filters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

const _book = BookSummary(
  id: 'b1',
  title: 'Pedro Páramo',
  author: 'Juan Rulfo',
  publisher: 'RM',
  minPrice: 89,
  totalStock: 4,
  storeCount: 2,
  storeIds: ['s1', 's2'],
);

const _page = BookPage(items: [_book], total: 30, page: 1);
const _novela = SearchFilters(genre: 'Novela');

void main() {
  late MockSearchRepository remote;
  late MemorySearchCacheDataSource cache;
  late CachedSearchRepository repo;
  var clock = DateTime(2026, 11, 21, 18, 5);

  setUp(() {
    registerFallbackValue(const SearchFilters());
    remote = MockSearchRepository();
    cache = MemorySearchCacheDataSource();
    repo = CachedSearchRepository(remote, cache, now: () => clock);
  });

  void answer(Future<BookPage> Function() result, {String? q = 'rulfo'}) =>
      when(
        () => remote.search(
          q: q,
          filters: any(named: 'filters'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) => result());

  group('CachedSearchRepository', () {
    test('saves the first page and serves it without connection', () async {
      answer(() async => _page);
      expect(await repo.search(q: 'rulfo'), same(_page));

      answer(() async => throw const NetworkFailure());
      final offline = await repo.search(q: 'rulfo');
      expect(offline.isOffline, isTrue);
      expect(offline.savedAt, clock);
      expect(offline.items.single.title, 'Pedro Páramo');
      expect(offline.items.single.storeIds, ['s1', 's2']);
      // Only the saved rows: no infinite scroll while offline.
      expect(offline.total, 1);
    });

    test('rethrows when nothing was saved or the error is not network', () {
      answer(() async => throw const NetworkFailure());
      expect(repo.search(q: 'rulfo'), throwsA(isA<NetworkFailure>()));
      answer(() async => throw const ServerFailure());
      expect(repo.search(q: 'rulfo'), throwsA(isA<ServerFailure>()));
    });

    test('order and "Solo disponibles" share the cached page', () async {
      answer(() async => _page, q: 'Rulfo ');
      await repo.search(q: 'Rulfo ');
      answer(() async => throw const NetworkFailure());
      final offline = await repo.search(
        q: 'rulfo',
        filters: const SearchFilters(onlyAvailable: true),
      );
      expect(offline.isOffline, isTrue);
    });

    test('next pages are not cached', () async {
      answer(() async => _page);
      await repo.search(q: 'rulfo', page: 2);
      expect(cache.all(), isEmpty);
    });

    test('counts searches and lists the most recent first', () async {
      answer(() async => _page);
      await repo.search(q: 'rulfo');
      clock = clock.add(const Duration(minutes: 1));
      answer(() async => _page, q: null);
      await repo.search(filters: _novela);
      clock = clock.add(const Duration(minutes: 1));
      await repo.search(q: 'rulfo');

      answer(() async => _page, q: null);
      await repo.search();

      final recent = await repo.recent();
      expect(recent.map((r) => r.label), ['rulfo', 'Novela']);
      expect(recent.first.count, 2);
      expect(recent.last.filters.genre, 'Novela');
    });

    test('a failing cache never breaks a search', () async {
      final broken = _BrokenCache();
      repo = CachedSearchRepository(remote, broken);
      answer(() async => _page);
      expect(await repo.search(q: 'rulfo'), same(_page));
    });
  });

  test('memory cache keeps the 20 most recent searches', () async {
    for (var i = 0; i < 22; i++) {
      await cache.write(
        CachedSearchModel.fromPage(
          q: 'q$i',
          filters: const SearchFilters(),
          page: _page,
          savedAt: DateTime(2026, 11, 1, 0, i),
        ),
      );
    }
    expect(cache.all(), hasLength(20));
    expect(
      cache.read(CachedSearchModel.keyFor('q0', const SearchFilters())),
      isNull,
    );
    expect(
      cache.read(CachedSearchModel.keyFor('q21', const SearchFilters())),
      isNotNull,
    );
  });

  group('Hive', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('bookia_hive');
      Hive.init(dir.path);
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CachedSearchAdapter());
      }
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await dir.delete(recursive: true);
    });

    test('the adapter round-trips a search through the box', () async {
      final source = HiveSearchCacheDataSource(
        await Hive.openBox<CachedSearchModel>(
          HiveSearchCacheDataSource.boxName,
        ),
      );
      final entry = CachedSearchModel.fromPage(
        q: 'rulfo',
        filters: const SearchFilters(
          genre: 'Novela',
          minPrice: 50,
          maxPrice: 120,
        ),
        page: _page,
        savedAt: DateTime(2026, 11, 21, 18, 5),
        count: 3,
      );
      await source.write(entry);
      await Hive.close();

      final reopened = HiveSearchCacheDataSource(
        await Hive.openBox<CachedSearchModel>(
          HiveSearchCacheDataSource.boxName,
        ),
      );
      final read = reopened.read(entry.key)!;
      expect(read.count, 3);
      expect(read.savedAt, DateTime(2026, 11, 21, 18, 5));
      expect(read.toRecentSearch().filters.maxPrice, 120);
      final b = read.bookEntities.single;
      expect(b.minPrice, 89);
      expect(b.totalStock, 4);
      expect(b.availability, Availability.available);
    });

    test('keeps only the 20 most recent searches', () async {
      final source = HiveSearchCacheDataSource(
        await Hive.openBox<CachedSearchModel>(
          HiveSearchCacheDataSource.boxName,
        ),
      );
      for (var i = 0; i < 21; i++) {
        await source.write(
          CachedSearchModel.fromPage(
            q: 'q$i',
            filters: const SearchFilters(),
            page: _page,
            savedAt: DateTime(2026, 11, 1, 0, i),
          ),
        );
      }
      expect(source.all(), hasLength(20));
      expect(
        source.read(CachedSearchModel.keyFor('q0', const SearchFilters())),
        isNull,
      );
    });
  });
}

class _BrokenCache implements SearchCacheDataSource {
  @override
  List<CachedSearchModel> all() => const [];

  @override
  CachedSearchModel? read(String key) => null;

  @override
  Future<void> write(CachedSearchModel entry) async =>
      throw const FileSystemException('disk full');
}
