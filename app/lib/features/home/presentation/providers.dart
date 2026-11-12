import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/home/data/repositories/home_repository_impl.dart';
import 'package:bookia_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(ref.watch(apiClientProvider)),
);
