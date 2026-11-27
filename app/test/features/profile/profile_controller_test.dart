import 'dart:async';

import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/profile/domain/entities/profile_user.dart';
import 'package:bookia_mobile/features/profile/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_test_helpers.dart';

ProviderContainer _container(FakeProfileRepository repository) {
  final container = ProviderContainer(
    overrides: [profileRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  container.read(currentSessionProvider.notifier).set(testSession());
  return container;
}

void main() {
  test('loads the account and synchronizes the shared session', () async {
    final repository = FakeProfileRepository(
      user: testProfileUser(name: 'Ana María', mustChangePassword: true),
    );
    final container = _container(repository);

    final user = await container.read(profileProvider.future);
    expect(user.name, 'Ana María');
    final session = container.read(currentSessionProvider) as SignedInSession;
    expect(session.name, 'Ana María');
    expect(session.email, 'ana@bookia.mx');
    expect(session.mustChangePassword, isTrue);
  });

  test('updates the name in the state and in the session', () async {
    final repository = FakeProfileRepository();
    repository.onUpdateName = (name) async {
      repository.user = testProfileUser(name: name);
      return repository.user;
    };
    final container = _container(repository);
    await container.read(profileProvider.future);

    await container.read(profileProvider.notifier).updateName('  Nueva  ');
    expect(repository.lastName, 'Nueva');
    expect(
      (container.read(currentSessionProvider) as SignedInSession).name,
      'Nueva',
    );
  });

  test('a failed name update keeps the old state', () async {
    final repository = FakeProfileRepository()
      ..onUpdateName = (_) => Future.error(const NetworkFailure());
    final container = _container(repository);
    await container.read(profileProvider.future);

    await expectLater(
      container.read(profileProvider.notifier).updateName('Otra'),
      throwsA(isA<NetworkFailure>()),
    );
    expect(container.read(profileProvider).value?.name, 'Ana');
  });

  test('a late response from another account is discarded', () async {
    final pending = Completer<ProfileUser>();
    final repository = FakeProfileRepository()..onMe = () => pending.future;
    final container = _container(repository);
    final future = container.read(profileProvider.future);

    container.read(currentSessionProvider.notifier).set(const GuestSession());
    pending.complete(testProfileUser(id: 'u2', name: 'Otra'));
    await expectLater(future, throwsA(isA<UnauthorizedFailure>()));
    expect(container.read(currentSessionProvider), isA<GuestSession>());
  });

  test('changing the password clears the forced-change flag', () async {
    final repository = FakeProfileRepository(
      user: testProfileUser(mustChangePassword: true),
    );
    final container = _container(repository);
    await container.read(profileProvider.future);

    repository.user = testProfileUser(mustChangePassword: false);
    await container
        .read(profileProvider.notifier)
        .changePassword(currentPassword: 'oldpass1', newPassword: 'newpass1');
    expect(
      (container.read(
        currentSessionProvider,
      ) as SignedInSession).mustChangePassword,
      isFalse,
    );
  });
}
