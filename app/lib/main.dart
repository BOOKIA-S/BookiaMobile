import 'package:bookia_mobile/app/app.dart';
import 'package:bookia_mobile/core/preferences/preferences_providers.dart';
import 'package:bookia_mobile/core/preferences/preferences_store.dart';
import 'package:bookia_mobile/features/search/data/datasources/local/search_cache_data_source.dart';
import 'package:bookia_mobile/features/search/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Offline cache of searches (I2-10). Never holds the token (SEG-01).
  await Hive.initFlutter();
  final searchCache = await HiveSearchCacheDataSource.open();
  // Preferences are non-sensitive; if Hive fails, use memory for this run.
  PreferencesStore preferences = MemoryPreferencesStore();
  try {
    preferences = await HivePreferencesStore.open();
  } on Object catch (error) {
    debugPrint('Preferences store unavailable: $error');
  }
  runApp(
    ProviderScope(
      overrides: [
        searchCacheProvider.overrideWithValue(searchCache),
        preferencesStoreProvider.overrideWithValue(preferences),
      ],
      child: const BookiaApp(),
    ),
  );
}
