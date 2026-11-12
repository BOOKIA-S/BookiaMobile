import 'package:bookia_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:bookia_mobile/features/home/presentation/providers.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

/// Overrides so app-level tests never hit the network.
List<Override> offlineOverrides({List<String> genres = const ['Novela']}) {
  final home = MockHomeRepository();
  when(home.getGenres).thenAnswer((_) async => genres);
  return [homeRepositoryProvider.overrideWithValue(home)];
}
