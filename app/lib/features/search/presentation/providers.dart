import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/search/data/repositories/search_repository_impl.dart';
import 'package:bookia_mobile/features/search/domain/repositories/search_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(ref.watch(apiClientProvider)),
);
