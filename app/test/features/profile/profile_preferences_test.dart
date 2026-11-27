import 'package:bookia_mobile/core/location/location_providers.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/core/preferences/preferences_providers.dart';
import 'package:bookia_mobile/core/preferences/preferences_store.dart';
import 'package:bookia_mobile/features/profile/presentation/widgets/profile_preferences_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _FailingPreferencesStore implements PreferencesStore {
  _FailingPreferencesStore({this.failRead = false});

  final bool failRead;

  @override
  Future<bool?> readBool(String key) async {
    if (failRead) throw StateError('read failed');
    return true;
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    throw StateError('write failed');
  }
}

Future<void> _pump(
  WidgetTester tester,
  PreferencesStore store, {
  MockLocationService? location,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        if (location != null)
          locationServiceProvider.overrideWithValue(location),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ProfilePreferencesSection()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('preferences persist across controllers using the same store', () async {
    final store = MemoryPreferencesStore();
    final first = ProviderContainer(
      overrides: [preferencesStoreProvider.overrideWithValue(store)],
    );
    addTearDown(first.dispose);
    expect(
      (await first.read(appPreferencesProvider.future)).useLocation,
      isTrue,
    );
    await first.read(appPreferencesProvider.notifier).setUseLocation(false);

    final second = ProviderContainer(
      overrides: [preferencesStoreProvider.overrideWithValue(store)],
    );
    addTearDown(second.dispose);
    expect(
      (await second.read(appPreferencesProvider.future)).useLocation,
      isFalse,
    );
  });

  test('a read failure starts with location off', () async {
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(
          _FailingPreferencesStore(failRead: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(
      (await container.read(appPreferencesProvider.future)).useLocation,
      isFalse,
    );
  });

  testWidgets('a write failure keeps the old value and informs the user', (
    tester,
  ) async {
    await _pump(tester, _FailingPreferencesStore());
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No pudimos guardar la preferencia'),
      findsOneWidget,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
  });

  testWidgets('a denied permission keeps the preference but explains it', (
    tester,
  ) async {
    final location = MockLocationService();
    when(location.requestAccess).thenAnswer((_) async => LocationAccess.denied);
    await _pump(
      tester,
      MemoryPreferencesStore({PreferenceKeys.useLocation: false}),
      location: location,
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('No hay permiso de ubicación'), findsOneWidget);
    verifyNever(location.currentPosition);
  });

  testWidgets('notifications are honestly shown as unavailable', (
    tester,
  ) async {
    await _pump(tester, MemoryPreferencesStore());
    expect(find.text('Notificaciones push'), findsOneWidget);
    expect(
      find.textContaining('No disponibles en esta compilación'),
      findsOneWidget,
    );
    expect(find.byType(SwitchListTile), findsOneWidget);
  });
}
