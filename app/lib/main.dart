import 'package:bookia_mobile/app/app.dart';
import 'package:bookia_mobile/core/notifications/firebase_push_service.dart';
import 'package:bookia_mobile/core/notifications/push_providers.dart';
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
  // Screen 13: without the Firebase config files push stays off (COD-06).
  final push = await FirebasePushService.initialize();
  runApp(
    ProviderScope(
      overrides: [
        searchCacheProvider.overrideWithValue(searchCache),
        if (push != null) pushServiceProvider.overrideWithValue(push),
      ],
      child: const BookiaApp(),
    ),
  );
}
