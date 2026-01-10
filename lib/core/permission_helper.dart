import 'dart:convert';
import 'dart:developer';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';

/// Permission keys for employee access control
class PermissionKeys {
  static const String addNewProduct = 'canAddProduct';
  static const String manageInventory = 'canManageInventory';
  static const String deleteProduct = 'canDeleteProduct';
}

/// Helper class to check employee permissions
class PermissionHelper {
  /// Check if the current user has a specific permission
  /// Managers always have all permissions
  /// Employees need to have the permission explicitly granted
  static Future<bool> hasPermission(String permissionKey) async {
    try {
      final userType = CacheHelper.getData(kUserType);

      // Managers have all permissions
      if (userType == kUserTypeManager) {
        return true;
      }

      // For employees, check their permissions
      if (userType == kUserTypeEmployee) {
        final permissionsString = CacheHelper.getData(kPermissions);

        if (permissionsString == null || permissionsString.isEmpty) {
          log('⚠️ No permissions found for employee');
          return false;
        }

        try {
          // Parse the permissions string to Map
          // The format is like: {canAddProduct: true, canManageInventory: false, ...}
          final permissionsMap = _parsePermissionsString(permissionsString);

          final hasAccess = permissionsMap[permissionKey] == true;
          log('🔐 Permission check for $permissionKey: $hasAccess');
          return hasAccess;
        } catch (e) {
          log('❌ Error parsing permissions: $e');
          return false;
        }
      }

      // Default: no permission
      return false;
    } catch (e) {
      log('❌ Error checking permission: $e');
      return false;
    }
  }

  /// Parse permissions string to Map
  /// Handles both JSON format and Dart Map toString format
  static Map<String, dynamic> _parsePermissionsString(
    String permissionsString,
  ) {
    try {
      // Try JSON format first
      return jsonDecode(permissionsString) as Map<String, dynamic>;
    } catch (e) {
      // If JSON fails, try parsing Dart Map toString format
      // Format: {key1: value1, key2: value2}
      final cleanedString = permissionsString
          .replaceAll('{', '')
          .replaceAll('}', '')
          .trim();

      final Map<String, dynamic> result = {};
      final pairs = cleanedString.split(',');

      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = keyValue[1].trim().toLowerCase();
          result[key] = value == 'true';
        }
      }

      return result;
    }
  }

  /// Check if user can add new products
  static Future<bool> canAddProduct() async {
    return await hasPermission(PermissionKeys.addNewProduct);
  }

  /// Check if user can manage inventory (sales)
  static Future<bool> canManageInventory() async {
    return await hasPermission(PermissionKeys.manageInventory);
  }

  /// Check if user can delete products
  static Future<bool> canDeleteProduct() async {
    return await hasPermission(PermissionKeys.deleteProduct);
  }
}
