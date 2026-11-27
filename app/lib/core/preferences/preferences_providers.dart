import 'package:bookia_mobile/core/preferences/preferences_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Device preferences that affect privacy and location. The token never
/// lives here (SEG-01); it stays in secure storage.
class AppPreferences {
  const AppPreferences({required this.useLocation});

  final bool useLocation;

  AppPreferences copyWith({bool? useLocation}) =>
      AppPreferences(useLocation: useLocation ?? this.useLocation);
}

/// Loaded once at startup. If the store cannot be read, location starts
/// disabled: the safe default for a privacy-related choice.
class AppPreferencesController extends AsyncNotifier<AppPreferences> {
  @override
  Future<AppPreferences> build() async {
    try {
      final stored = await ref
          .watch(preferencesStoreProvider)
          .readBool(PreferenceKeys.useLocation);
      return AppPreferences(useLocation: stored ?? true);
    } on Object {
      return const AppPreferences(useLocation: false);
    }
  }

  Future<void> setUseLocation(bool value) async {
    await ref
        .read(preferencesStoreProvider)
        .writeBool(PreferenceKeys.useLocation, value);
    if (ref.mounted) state = AsyncData(AppPreferences(useLocation: value));
  }
}

/// Widget tests get an in-memory store; main overrides it with Hive.
final preferencesStoreProvider = Provider<PreferencesStore>(
  (_) => MemoryPreferencesStore(),
);

final appPreferencesProvider =
    AsyncNotifierProvider<AppPreferencesController, AppPreferences>(
      AppPreferencesController.new,
    );
