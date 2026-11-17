import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:bookia_mobile/features/onboarding/domain/usecases/answer_location_prompt.dart';
import 'package:bookia_mobile/features/onboarding/domain/usecases/should_ask_location.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockLocationService location;
  late MockOnboardingRepository repository;

  setUp(() {
    location = MockLocationService();
    repository = MockOnboardingRepository();
    when(repository.markLocationAsked).thenAnswer((_) async {});
  });

  group('ShouldAskLocation', () {
    test('asks the first time while the permission is missing', () async {
      when(repository.wasLocationAsked).thenAnswer((_) async => false);
      when(location.checkAccess).thenAnswer((_) async => LocationAccess.denied);
      expect(await ShouldAskLocation(location, repository).call(), isTrue);
    });

    test('does not ask when the permission is already granted', () async {
      when(repository.wasLocationAsked).thenAnswer((_) async => false);
      when(location.checkAccess)
          .thenAnswer((_) async => LocationAccess.granted);
      expect(await ShouldAskLocation(location, repository).call(), isFalse);
    });

    test('never asks twice', () async {
      when(repository.wasLocationAsked).thenAnswer((_) async => true);
      expect(await ShouldAskLocation(location, repository).call(), isFalse);
      verifyNever(location.checkAccess);
    });
  });

  group('AnswerLocationPrompt', () {
    test('allow remembers the answer and shows the system dialog', () async {
      when(location.requestAccess)
          .thenAnswer((_) async => LocationAccess.granted);
      final access = await AnswerLocationPrompt(location, repository).allow();

      expect(access, LocationAccess.granted);
      verify(repository.markLocationAsked).called(1);
    });

    test('skip only remembers the answer', () async {
      await AnswerLocationPrompt(location, repository).skip();
      verify(repository.markLocationAsked).called(1);
      verifyNever(location.requestAccess);
    });
  });

  group('OnboardingRepositoryImpl', () {
    late _MockStorage storage;
    late OnboardingRepositoryImpl repo;

    setUp(() {
      storage = _MockStorage();
      repo = OnboardingRepositoryImpl(storage: storage);
    });

    test('reads and writes the flag', () async {
      when(() => storage.read(key: OnboardingRepositoryImpl.key))
          .thenAnswer((_) async => 'true');
      when(
        () => storage.write(key: OnboardingRepositoryImpl.key, value: 'true'),
      ).thenAnswer((_) async {});

      expect(await repo.wasLocationAsked(), isTrue);
      await repo.markLocationAsked();
      verify(
        () => storage.write(key: OnboardingRepositoryImpl.key, value: 'true'),
      ).called(1);
    });

    test('a missing flag means not asked', () async {
      when(() => storage.read(key: OnboardingRepositoryImpl.key))
          .thenAnswer((_) async => null);
      expect(await repo.wasLocationAsked(), isFalse);
    });

    test('storage errors never break the start of the app', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenThrow(PlatformException(code: 'fail'));
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(PlatformException(code: 'fail'));

      expect(await repo.wasLocationAsked(), isFalse);
      await expectLater(repo.markLocationAsked(), completes);
    });
  });
}
