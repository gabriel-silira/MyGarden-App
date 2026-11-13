import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferencesStore {
  Future<String?> read();
  Future<void> write(String value);
}

class LocalPreferencesStore implements PreferencesStore {
  LocalPreferencesStore({this.storageKey = 'mygarden.preferences.v1'});

  /// Allows device integration tests to use their own persisted data.
  final String storageKey;
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  @override
  Future<String?> read() => _preferences.getString(storageKey);
  @override
  Future<void> write(String value) => _preferences.setString(storageKey, value);
}

class MemoryPreferencesStore implements PreferencesStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}
