import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static late SharedPreferences prefs;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return; // Already initialized
    prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  static bool get isInitialized => _isInitialized;

  static String? getDataString(String key) {
    return prefs.getString(key);
  }

  static dynamic getData(String key) {
    return prefs.get(key);
  }

  static Future<bool> saveData(String key, dynamic value) async {
    if (value is bool) return prefs.setBool(key, value);
    if (value is String) return prefs.setString(key, value);
    if (value is int) return prefs.setInt(key, value);
    return prefs.setDouble(key, value);
  }

  static Future<bool> removeData(String key) async {
    return prefs.remove(key);
  }

  static bool containsKey(String key) {
    return prefs.containsKey(key);
  }

  static Future<bool> clear() async {
    return prefs.clear();
  }
}
