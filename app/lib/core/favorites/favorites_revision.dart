import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Grows whenever the reader adds or removes a favorite, so the profile
/// counters refresh without importing the books feature.
class FavoritesRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final favoritesRevisionProvider = NotifierProvider<FavoritesRevision, int>(
  FavoritesRevision.new,
);
