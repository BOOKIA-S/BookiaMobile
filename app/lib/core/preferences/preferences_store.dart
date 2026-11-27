import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Keys of the on-device preferences. Never used for the session token.
abstract final class PreferenceKeys {
  static const useLocation = 'use_location';
}

/// Small key/value store for non-sensitive device preferences.
abstract interface class PreferencesStore {
  Future<bool?> readBool(String key);

  Future<void> writeBool(String key, bool value);
}

/// Volatile default for widget tests and for a failed Hive open.
class MemoryPreferencesStore implements PreferencesStore {
  MemoryPreferencesStore([Map<String, bool>? values]) : _values = {...?values};

  final Map<String, bool> _values;

  @override
  Future<bool?> readBool(String key) async => _values[key];

  @override
  Future<void> writeBool(String key, bool value) async {
    _values[key] = value;
  }
}

/// Hive box `preferences`, opened once in main.
class HivePreferencesStore implements PreferencesStore {
  const HivePreferencesStore(this._box);

  static const boxName = 'preferences';
  final Box<bool> _box;

  /// Opens the box for the app. Call after `Hive.initFlutter()`.
  static Future<HivePreferencesStore> open() async =>
      HivePreferencesStore(await Hive.openBox<bool>(boxName));

  @override
  Future<bool?> readBool(String key) async => _box.get(key);

  @override
  Future<void> writeBool(String key, bool value) async {
    await _box.put(key, value);
  }
}
