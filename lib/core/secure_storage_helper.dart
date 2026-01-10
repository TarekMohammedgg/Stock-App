import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class SecureStorageHelper {
  static const _storage = FlutterSecureStorage();

  

  /// Write data securely
  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
    
  }

  /// Read data securely
  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete specific key
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Clear all secure storage
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
