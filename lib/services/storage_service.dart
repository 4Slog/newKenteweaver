import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<String?> read(String key) async {
    return _prefs.getString(key);
  }

  Future<bool> write(String key, String value) async {
    return _prefs.setString(key, value);
  }

  Future<bool> delete(String key) async {
    return _prefs.remove(key);
  }

  Future<bool> clear() async {
    return _prefs.clear();
  }

  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
}
