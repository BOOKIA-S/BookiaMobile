import 'package:bookia_mobile/features/search/domain/entities/recent_search.dart';

/// Searches saved on the phone (I2-10). Implemented in data/ (PAT-01).
abstract interface class SearchHistoryRepository {
  /// Most recent first, at most [limit].
  Future<List<RecentSearch>> recent({int limit = 5});
}
