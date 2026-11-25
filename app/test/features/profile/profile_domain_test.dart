import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/profile/domain/usecases/change_password.dart';
import 'package:bookia_mobile/features/profile/domain/usecases/update_name.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_test_helpers.dart';

void main() {
  group('UpdateName', () {
    late FakeProfileRepository repository;
    late UpdateName update;

    setUp(() {
      repository = FakeProfileRepository();
      update = UpdateName(repository);
    });

    test('trims the name before sending it', () async {
      await update('  Ana María  ');
      expect(repository.lastName, 'Ana María');
    });

    test('rejects empty and whitespace-only names without a request', () {
      for (final name in ['', '   ']) {
        expect(() => update(name), throwsA(isA<ValidationFailure>()));
      }
      expect(repository.updateCalls, 0);
    });

    test('rejects names longer than 80 characters', () {
      expect(() => update('a' * 81), throwsA(isA<ValidationFailure>()));
      expect(repository.updateCalls, 0);
    });
  });

  group('ChangePassword', () {
    late FakeProfileRepository repository;
    late ChangePassword change;

    setUp(() {
      repository = FakeProfileRepository();
      change = ChangePassword(repository);
    });

    test('accepts 8 to 200 characters', () async {
      await change(currentPassword: 'oldpass1', newPassword: 'newpass1');
      expect(repository.passwordCalls, 1);
    });

    test('rejects an empty current password', () async {
      expect(
        () => change(currentPassword: '', newPassword: 'newpass1'),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.passwordCalls, 0);
    });

    test('rejects short, long and repeated passwords', () async {
      for (final value in ['short', 'a' * 201, 'samepass1']) {
        expect(
          () => change(
            currentPassword: value == 'samepass1' ? value : 'oldpass1',
            newPassword: value,
          ),
          throwsA(isA<ValidationFailure>()),
        );
      }
      expect(repository.passwordCalls, 0);
    });
  });
}
