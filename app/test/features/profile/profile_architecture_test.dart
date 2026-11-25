import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Scoped architecture checks for the new profile feature. The repository
/// has pre-existing ARQ-04 debt elsewhere; these checks do not fail the suite
/// because of modules owned by other members.
void main() {
  final files = Directory('lib/features/profile')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('profile does not import internals of other features', () {
    final forbidden = RegExp(
      r'package:bookia_mobile/features/(auth|books|reservations|search|stores|home|staff|splash|scanner|onboarding|notifications)/',
    );
    final violations = <String>[];
    for (final file in files) {
      final matches = forbidden
          .allMatches(file.readAsStringSync())
          .map((m) => m.group(0))
          .toList();
      if (matches.isNotEmpty) violations.add('${file.path}: $matches');
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('profile files stay under the 300-line limit', () {
    final over = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync().length;
      if (lines > 300) over.add('${file.path}: $lines');
    }
    expect(over, isEmpty, reason: over.join('\n'));
  });

  test('profile imports shared contracts instead of feature internals', () {
    final source = files.map((f) => f.readAsStringSync()).join('\n');
    expect(
      source,
      contains('package:bookia_mobile/core/session/session_status.dart'),
    );
    expect(
      source,
      contains('package:bookia_mobile/core/favorites/favorite_book.dart'),
    );
  });
}
