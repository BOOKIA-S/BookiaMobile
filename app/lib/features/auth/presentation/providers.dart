import 'package:bookia_mobile/core/di/providers.dart';
import 'package:bookia_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:bookia_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bookia_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    AuthRemoteDataSource(
      ref.watch(apiClientProvider).post<Map<String, dynamic>>,
    ),
  ),
);
