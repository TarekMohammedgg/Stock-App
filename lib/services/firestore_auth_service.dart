// import 'dart:convert';
// import 'dart:developer';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:gdrive_tutorial/core/consts.dart';
// import 'package:gdrive_tutorial/core/shared_prefs.dart';
// import 'package:gdrive_tutorial/core/secure_storage_helper.dart';

// /// Unified service for Firestore-based authentication
// /// Supports both managers and employees with all auth operations
// class FirestoreAuthService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // ==================== LOGIN & AUTHENTICATION ====================

//   /// Login user with username and password
//   /// [userType] should be either 'manager' or 'employee'
//   Future<Map<String, dynamic>?> loginUser({
//     required String username,
//     required String password,
//     required String userType,
//   }) async {
//     try {
//       log('🔐 Attempting login for $userType: $username');

//       // Determine collection based on user type
//       final collection = userType == kUserTypeManager
//           ? kManagersCollection
//           : kEmployeesCollection;

//       log("the collection name is : $collection");
//       // Query for user by username field (not document ID)
//       final querySnapshot = await _firestore
//           .collection(collection)
//           .where(kEmployeeUsername, isEqualTo: username)
//           .limit(1)
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         log('❌ User not found: $username');
//         return null;
//       }

//       final userDoc = querySnapshot.docs.first;
//       final userData = userDoc.data();

//       // Check if user is active
//       final isActive = userData[kEmployeeIsActive] ?? true;
//       if (!isActive) {
//         log('❌ User account is inactive: $username');
//         throw Exception(
//           'Account is inactive. Please contact your administrator.',
//         );
//       }

//       // Verify password (plain text comparison)
//       final storedPassword = userData[kEmployeePassword] as String?;

//       if (storedPassword != password) {
//         log('❌ Invalid password for user: $username');
//         return null;
//       }

//       // For employees, get manager's access token
//       if (userType == kUserTypeEmployee) {
//         final managerEmail = userData[kEmployeeManagerEmail] as String;
//         final accessToken = await getManagerAccessToken(managerEmail);

//         if (accessToken == null) {
//           log('❌ Failed to get manager access token');
//           return null;
//         }

//         // Save employee data locally
//         await _saveEmployeeLocalData(userData, accessToken, userDoc.id);
//       } else {
//         // Save manager data locally
//         await _saveManagerLocalData(userData);
//       }

//       // Update last login timestamp
//       await _firestore.collection(collection).doc(userDoc.id).update({
//         kEmployeeLastLogin: FieldValue.serverTimestamp(),
//       });

//       log('✅ Login successful for $userType: $username');
//       return userData;
//     } catch (e) {
//       log('❌ Login error: $e');
//       rethrow;
//     }
//   }

//   /// Employee login with username and password (legacy method)
//   Future<Map<String, dynamic>?> loginAsEmployee({
//     required String username,
//     required String password,
//   }) async {
//     final result = await loginUser(
//       username: username,
//       password: password,
//       userType: kUserTypeEmployee,
//     );

//     if (result == null) return null;

//     return {
//       'employeeId': CacheHelper.getData(kEmployeeId),
//       'username': username,
//       'displayName': result[kEmployeeDisplayName],
//       'managerEmail': result[kEmployeeManagerEmail],
//       'roles': result[kEmployeeRoles],
//       'permissions': result[kEmployeePermissions],
//     };
//   }

//   /// Save employee data locally
//   Future<void> _saveEmployeeLocalData(
//     Map<String, dynamic> employeeData,
//     String accessToken,
//     String employeeId,
//   ) async {
//     await CacheHelper.saveData(kEmployeeId, employeeId);
//     await CacheHelper.saveData(kUsername, employeeData[kEmployeeUsername]);
//     await CacheHelper.saveData(
//       kDisplayName,
//       employeeData[kEmployeeDisplayName],
//     );
//     await CacheHelper.saveData(kEmail, employeeData[kEmployeeManagerEmail]);
//     await CacheHelper.saveData(kIsLogin, true);
//     await CacheHelper.saveData(kUserType, kUserTypeEmployee);

//     // Store permissions for role-based access control
//     final permissions =
//         employeeData[kEmployeePermissions] as Map<String, dynamic>?;
//     if (permissions != null) {
//       await CacheHelper.saveData('Permissions', permissions.toString());
//     }

//     log('✅ Saved employee data locally');
//   }

//   /// Save manager data locally
//   Future<void> _saveManagerLocalData(Map<String, dynamic> managerData) async {
//     await CacheHelper.saveData(kEmail, managerData[kManagerEmail]);
//     await CacheHelper.saveData(kUsername, managerData[kEmployeeUsername]);
//     await CacheHelper.saveData(
//       kDisplayName,
//       managerData[kEmployeeDisplayName] ?? managerData[kEmployeeUsername],
//     );
//     await CacheHelper.saveData(kIsLogin, true);
//     await CacheHelper.saveData(kUserType, kUserTypeManager);

//     log('✅ Saved manager data locally');
//   }

//   // ==================== MANAGER TOKEN MANAGEMENT ====================

//   /// Get manager's access token from Firestore (for employees to use)
//   Future<String?> getManagerAccessToken(String managerEmail) async {
//     try {
//       final managerDoc = await _firestore
//           .collection(kManagersCollection)
//           .doc(managerEmail)
//           .get();

//       if (!managerDoc.exists) {
//         log('❌ Manager not found: $managerEmail');
//         return null;
//       }

//       final data = managerDoc.data()!;
//       final token = data[kManagerAccessToken] as String?;
//       final expiresAt = (data[kManagerTokenExpiresAt] as Timestamp?)?.toDate();

//       // Check if token is expired
//       if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
//         log('⚠️ Manager token expired, needs refresh');
//         return null;
//       }

//       return token;
//     } catch (e) {
//       log('❌ Error getting manager token: $e');
//       return null;
//     }
//   }

//   Future<String?> getAccessToken() async {
//     try {
//       // final employeeId = CacheHelper.getData(kEmployeeId);
//       // if (employeeId == null) return null;

//       // Get employee's manager email
//       final employeeDoc = await _firestore
//           .collection(kEmployeesCollection)
//           .doc(employeeId)
//           .get();

//       if (!employeeDoc.exists) return null;

//       final managerEmail = employeeDoc.data()![kEmployeeManagerEmail] as String;

//       // Get manager's current access token
//       return await getManagerAccessToken(managerEmail);
//     } catch (e) {
//       log('❌ Error getting access token: $e');
//       return null;
//     }
//   }

//   // ==================== EMPLOYEE MANAGEMENT ====================

//   /// Create new employee (manager only)
//   Future<bool> createEmployee({
//     required String username,
//     required String password,
//     required String displayName,
//     required String managerEmail,
//     required List<String> roles,
//     required Map<String, bool> permissions,
//   }) async {
//     try {
//       // Check if username already exists
//       final existingUser = await _firestore
//           .collection(kEmployeesCollection)
//           .where(kEmployeeUsername, isEqualTo: username)
//           .limit(1)
//           .get();

//       if (existingUser.docs.isNotEmpty) {
//         log('❌ Username already exists');
//         return false;
//       }

//       // Create employee document
//       final employeeData = {
//         kEmployeeUsername: username,
//         kEmployeePassword: password,
//         kEmployeeDisplayName: displayName,
//         kEmployeeManagerEmail: managerEmail,
//         kEmployeeRoles: roles,
//         kEmployeePermissions: permissions,
//         kEmployeeIsActive: true,
//         kEmployeeCreatedAt: FieldValue.serverTimestamp(),
//         kEmployeeCreatedBy: managerEmail,
//       };

//       await _firestore.collection(kEmployeesCollection).add(employeeData);

//       log('✅ Employee created successfully: $username');
//       return true;
//     } catch (e) {
//       log('❌ Error creating employee: $e');
//       return false;
//     }
//   }

//   /// Get all employees for a manager
//   Future<List<Map<String, dynamic>>> getEmployees(String managerEmail) async {
//     try {
//       log('📋 Fetching employees for manager: $managerEmail');

//       final querySnapshot = await _firestore
//           .collection(kEmployeesCollection)
//           .where(kEmployeeManagerEmail, isEqualTo: managerEmail)
//           .get();

//       log('✅ Found ${querySnapshot.docs.length} employees');

//       final employees = querySnapshot.docs.map((doc) {
//         final data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();

//       // Sort by createdAt locally (if available)
//       employees.sort((a, b) {
//         final aTime = a[kEmployeeCreatedAt] as Timestamp?;
//         final bTime = b[kEmployeeCreatedAt] as Timestamp?;
//         if (aTime == null || bTime == null) return 0;
//         return bTime.compareTo(aTime); // descending order
//       });

//       return employees;
//     } catch (e, stackTrace) {
//       log('❌ Error getting employees: $e');
//       log('Stack trace: $stackTrace');
//       return [];
//     }
//   }

//   /// Update employee status (activate/deactivate)
//   Future<bool> updateEmployeeStatus({
//     required String employeeId,
//     required bool isActive,
//   }) async {
//     try {
//       await _firestore.collection(kEmployeesCollection).doc(employeeId).update({
//         kEmployeeIsActive: isActive,
//       });

//       log('✅ Employee status updated: $employeeId -> $isActive');
//       return true;
//     } catch (e) {
//       log('❌ Error updating employee status: $e');
//       return false;
//     }
//   }

//   /// Update employee permissions
//   Future<bool> updateEmployeePermissions({
//     required String employeeId,
//     required Map<String, bool> permissions,
//   }) async {
//     try {
//       await _firestore.collection(kEmployeesCollection).doc(employeeId).update({
//         kEmployeePermissions: permissions,
//       });

//       log('✅ Employee permissions updated: $employeeId');
//       return true;
//     } catch (e) {
//       log('❌ Error updating employee permissions: $e');
//       return false;
//     }
//   }

//   /// Delete employee
//   Future<bool> deleteEmployee(String employeeId) async {
//     try {
//       await _firestore
//           .collection(kEmployeesCollection)
//           .doc(employeeId)
//           .delete();

//       log('✅ Employee deleted: $employeeId');
//       return true;
//     } catch (e) {
//       log('❌ Error deleting employee: $e');
//       return false;
//     }
//   }

//   // ==================== PERMISSIONS & USER DATA ====================

//   /// Get user data from Firestore
//   Future<Map<String, dynamic>?> getUserData(
//     String username,
//     String userType,
//   ) async {
//     try {
//       final collection = userType == kUserTypeManager
//           ? kManagersCollection
//           : kEmployeesCollection;

//       final userDoc = await _firestore
//           .collection(collection)
//           .doc(username)
//           .get();

//       if (!userDoc.exists) {
//         return null;
//       }

//       return userDoc.data();
//     } catch (e) {
//       log('❌ Error getting user data: $e');
//       return null;
//     }
//   }

//   /// Check if employee has specific permission
//   Future<bool> hasPermission(String permissionKey) async {
//     try {
//       final userType = CacheHelper.getData(kUserType);

//       // Managers have all permissions
//       if (userType == kUserTypeManager) {
//         return true;
//       }

//       // Get permissions from local storage
//       final permissionsJson = CacheHelper.getData(kPermissions);
//       if (permissionsJson == null) {
//         return false;
//       }

//       final permissions = jsonDecode(permissionsJson) as Map<String, dynamic>;
//       return permissions[permissionKey] == true;
//     } catch (e) {
//       log('❌ Error checking permission: $e');
//       return false;
//     }
//   }

//   // ==================== MANAGER CREDENTIALS ====================

//   /// Update manager credentials in Firestore and local storage
//   Future<void> updateManagerCredentials({
//     required String username,
//     required String spreadsheetId,
//     required String driveFolderId,
//     required String appScriptUrl,
//   }) async {
//     try {
//       log('📝 Updating credentials for manager: $username');

//       final data = {
//         kManagerSpreadsheetId: spreadsheetId,
//         kManagerDriveFolderId: driveFolderId,
//         kManagerAppScriptUrl: appScriptUrl,
//       };

//       // Update Firestore (Querying by username field as done in login)
//       final querySnapshot = await _firestore
//           .collection(kManagersCollection)
//           .where(kEmployeeUsername, isEqualTo: username)
//           .limit(1)
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         throw Exception('Manager document not found for username: $username');
//       }

//       final docId = querySnapshot.docs.first.id;
//       await _firestore.collection(kManagersCollection).doc(docId).update(data);

//       // Update secure storage
//       await SecureStorageHelper.write(kSpreadsheetId, spreadsheetId);
//       await SecureStorageHelper.write(kDriveFolderId, driveFolderId);
//       await SecureStorageHelper.write(kAppScriptUrl, appScriptUrl);

//       log('✅ Credentials updated successfully');
//     } catch (e) {
//       log('❌ Error updating credentials: $e');
//       rethrow;
//     }
//   }

//   /// Register a new manager
//   /// Account is created as inactive by default
//   Future<void> registerManager({
//     required String username,
//     required String email,
//     required String password,
//   }) async {
//     try {
//       log('📝 Registering new manager: $username');

//       // Check if username already exists
//       final usernameQuery = await _firestore
//           .collection(kManagersCollection)
//           .where(kEmployeeUsername, isEqualTo: username)
//           .limit(1)
//           .get();

//       if (usernameQuery.docs.isNotEmpty) {
//         throw Exception('Username already taken');
//       }

//       // Check if email already exists
//       final emailQuery = await _firestore
//           .collection(kManagersCollection)
//           .where(kManagerEmail, isEqualTo: email)
//           .limit(1)
//           .get();

//       if (emailQuery.docs.isNotEmpty) {
//         throw Exception('Email already registered');
//       }

//       final data = {
//         kEmployeeUsername: username,
//         kManagerEmail: email,
//         kEmployeePassword: password,
//         kEmployeeDisplayName: username,
//         kEmployeeIsActive: false, // Default to inactive as requested
//         kManagerCreatedAt: FieldValue.serverTimestamp(),
//         kManagerSpreadsheetId: "",
//         kManagerDriveFolderId: "",
//         kManagerAppScriptUrl: "",
//       };

//       await _firestore.collection(kManagersCollection).doc(email).set(data);
//       log('✅ Manager registered successfully (inactive)');
//     } catch (e) {
//       log('❌ Registration error: $e');
//       rethrow;
//     }
//   }

//   // ==================== LOGOUT & SESSION ====================

//   /// Logout user
//   Future<void> logout() async {
//     try {
//       await CacheHelper.saveData('IsLogin', false);
//       await CacheHelper.saveData('UserType', null);
//       await CacheHelper.saveData('Username', null);
//       await CacheHelper.saveData('Email', null);
//       await CacheHelper.saveData('DisplayName', null);
//       await CacheHelper.saveData('ManagerEmail', null);
//       await CacheHelper.saveData('Roles', null);
//       await CacheHelper.saveData('Permissions', null);
//       await CacheHelper.saveData(kEmployeeId, null);

//       log('✅ Logout successful');
//     } catch (e) {
//       log('❌ Logout error: $e');
//     }
//   }

//   /// Check if user is logged in
//   bool isLoggedIn() {
//     return CacheHelper.getData(kIsLogin) ?? false;
//   }

//   /// Get current user type
//   String? getUserType() {
//     return CacheHelper.getData(kUserType);
//   }

//   /// Get current username
//   String? getUsername() {
//     return CacheHelper.getData(kUsername);
//   }
// }

import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';

/// Unified service for Firestore-based authentication
/// Supports both managers and employees
class FirestoreAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== LOGIN & AUTHENTICATION ====================

  /// Login user with username and password
  /// [userType] should be either 'manager' or 'employee'
  Future<Map<String, dynamic>?> loginUser({
    required String username,
    required String password,
    required String userType,
  }) async {
    try {
      log('🔐 Attempting login for $userType: $username');

      // Determine collection based on user type
      final collection = userType == kUserTypeManager
          ? kManagersCollection
          : kEmployeesCollection;

      // Query for user by username field
      final querySnapshot = await _firestore
          .collection(collection)
          .where(kEmployeeUsername, isEqualTo: username)
          .limit(1)
          .get();
      log(collection);

      if (querySnapshot.docs.isEmpty) {
        log('❌ User not found: $username');
        return null;
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();

      // Check if user is active
      final isActive = userData[kEmployeeIsActive] ?? true;

      // Allow inactive employees to login regardless of status
      // valid login leads to PendingActivationView if inactive
      if (!isActive) {
        log(
          '⚠️ Account is inactive: $username (allowing login for pending view)',
        );
      }

      // Verify password (plain text comparison as per your implementation)
      final storedPassword = userData[kEmployeePassword] as String?;

      if (storedPassword != password) {
        log('❌ Invalid password for user: $username');
        return null;
      }

      // Handle local data saving based on role
      if (userType == kUserTypeEmployee) {
        // Save employee data locally (No token required anymore)
        await _saveEmployeeLocalData(userData, userDoc.id);
      } else {
        // Save manager data locally (including isActive status)
        await _saveManagerLocalData(userData);
      }

      // Update last login timestamp in Firestore
      await _firestore.collection(collection).doc(userDoc.id).update({
        kEmployeeLastLogin: FieldValue.serverTimestamp(),
      });

      log('✅ Login successful for $userType: $username');
      return userData;
    } catch (e) {
      log('❌ Login error: $e');
      rethrow;
    }
  }

  /// Employee login with username and password (legacy method wrapper)
  Future<Map<String, dynamic>?> loginAsEmployee({
    required String username,
    required String password,
  }) async {
    final result = await loginUser(
      username: username,
      password: password,
      userType: kUserTypeEmployee,
    );

    if (result == null) return null;

    return {
      'employeeId': CacheHelper.getData(kEmployeeId),
      'username': username,
      'displayName': result[kEmployeeDisplayName],
      'managerEmail': result[kEmployeeManagerEmail],
      'roles': result[kEmployeeRoles],
      'permissions': result[kEmployeePermissions],
    };
  }

  /// Save employee data locally
  /// Also fetches manager's work location for attendance verification
  Future<void> _saveEmployeeLocalData(
    Map<String, dynamic> employeeData,
    String employeeId,
  ) async {
    await CacheHelper.saveData(kEmployeeId, employeeId);
    await CacheHelper.saveData(kUsername, employeeData[kEmployeeUsername]);
    await CacheHelper.saveData(
      kDisplayName,
      employeeData[kEmployeeDisplayName],
    );
    await CacheHelper.saveData(kEmail, employeeData[kEmployeeManagerEmail]);
    await CacheHelper.saveData(kIsLogin, true);
    await CacheHelper.saveData(kUserType, kUserTypeEmployee);

    // Save employee's active status for pending activation check
    final isActive = employeeData[kEmployeeIsActive] ?? false;
    await CacheHelper.saveData(kPrefEmployeeIsActive, isActive);

    // Store permissions for role-based access control
    final permissions =
        employeeData[kEmployeePermissions] as Map<String, dynamic>?;
    if (permissions != null) {
      await CacheHelper.saveData('Permissions', permissions.toString());
    }

    // Fetch manager's work location from Firestore
    final managerEmail = employeeData[kEmployeeManagerEmail] as String?;
    if (managerEmail != null && managerEmail.isNotEmpty) {
      try {
        final managerDoc = await _firestore
            .collection(kManagersCollection)
            .doc(managerEmail)
            .get();

        if (managerDoc.exists) {
          final managerData = managerDoc.data();
          final workLocation =
              managerData?[kManagerWorkLocation] as Map<String, dynamic>?;

          if (workLocation != null) {
            final latitude = workLocation[kWorkLatitude] as double?;
            final longitude = workLocation[kWorkLongitude] as double?;

            if (latitude != null && longitude != null) {
              await CacheHelper.saveData(kPrefWorkLatitude, latitude);
              await CacheHelper.saveData(kPrefWorkLongitude, longitude);
              log(
                '✅ Saved manager work location to prefs: $latitude, $longitude',
              );
            }
          } else {
            log('⚠️ Manager work location not set');
          }
        }
      } catch (e) {
        log('⚠️ Error fetching manager work location: $e');
      }
    }

    log('✅ Saved employee data locally');
  }

  /// Save manager data locally
  Future<void> _saveManagerLocalData(Map<String, dynamic> managerData) async {
    await CacheHelper.saveData(kEmail, managerData[kManagerEmail]);
    await CacheHelper.saveData(kUsername, managerData[kEmployeeUsername]);
    await CacheHelper.saveData(
      kDisplayName,
      managerData[kEmployeeDisplayName] ?? managerData[kEmployeeUsername],
    );
    await CacheHelper.saveData(kIsLogin, true);
    await CacheHelper.saveData(kUserType, kUserTypeManager);

    // Save manager's active status for pending activation check
    final isActive = managerData[kEmployeeIsActive] ?? false;
    await CacheHelper.saveData(kPrefManagerIsActive, isActive);

    log('✅ Saved manager data locally (isActive: $isActive)');
  }

  // ==================== EMPLOYEE MANAGEMENT ====================

  /// Check if username is already taken
  Future<bool> isUsernameTaken(String username) async {
    try {
      final existingUser = await _firestore
          .collection(kEmployeesCollection)
          .where(kEmployeeUsername, isEqualTo: username)
          .limit(1)
          .get();
      return existingUser.docs.isNotEmpty;
    } catch (e) {
      log('❌ Error checking username: $e');
      return false;
    }
  }

  /// Create new employee (manager only)
  Future<bool> createEmployee({
    required String username,
    required String password,
    required String displayName,
    required String managerEmail,
    required List<String> roles,
    required Map<String, bool> permissions,
  }) async {
    try {
      // Check if username already exists
      final existingUser = await _firestore
          .collection(kEmployeesCollection)
          .where(kEmployeeUsername, isEqualTo: username)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        log('❌ Username already exists');
        return false;
      }

      // Create employee document
      final employeeData = {
        kEmployeeUsername: username,
        kEmployeePassword: password,
        kEmployeeDisplayName: displayName,
        kEmployeeManagerEmail: managerEmail,
        kEmployeeRoles: roles,
        kEmployeePermissions: permissions,
        kEmployeeIsActive: true,
        kEmployeeCreatedAt: FieldValue.serverTimestamp(),
        kEmployeeCreatedBy: managerEmail,
      };

      await _firestore.collection(kEmployeesCollection).add(employeeData);

      log('✅ Employee created successfully: $username');
      return true;
    } catch (e) {
      log('❌ Error creating employee: $e');
      return false;
    }
  }

  /// Get all employees for a manager
  Future<List<Map<String, dynamic>>> getEmployees(String managerEmail) async {
    try {
      log('📋 Fetching employees for manager: $managerEmail');

      final querySnapshot = await _firestore
          .collection(kEmployeesCollection)
          .where(kEmployeeManagerEmail, isEqualTo: managerEmail)
          .get();

      log('✅ Found ${querySnapshot.docs.length} employees');

      final employees = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by createdAt locally
      employees.sort((a, b) {
        final aTime = a[kEmployeeCreatedAt] as Timestamp?;
        final bTime = b[kEmployeeCreatedAt] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime); // descending order
      });

      return employees;
    } catch (e, stackTrace) {
      log('❌ Error getting employees: $e');
      log('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Update employee status (activate/deactivate)
  Future<bool> updateEmployeeStatus({
    required String employeeId,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection(kEmployeesCollection).doc(employeeId).update({
        kEmployeeIsActive: isActive,
      });

      log('✅ Employee status updated: $employeeId -> $isActive');
      return true;
    } catch (e) {
      log('❌ Error updating employee status: $e');
      return false;
    }
  }

  /// Update employee permissions
  Future<bool> updateEmployeePermissions({
    required String employeeId,
    required Map<String, bool> permissions,
  }) async {
    try {
      await _firestore.collection(kEmployeesCollection).doc(employeeId).update({
        kEmployeePermissions: permissions,
      });

      log('✅ Employee permissions updated: $employeeId');
      return true;
    } catch (e) {
      log('❌ Error updating employee permissions: $e');
      return false;
    }
  }

  /// Delete employee
  Future<bool> deleteEmployee(String employeeId) async {
    try {
      await _firestore
          .collection(kEmployeesCollection)
          .doc(employeeId)
          .delete();

      log('✅ Employee deleted: $employeeId');
      return true;
    } catch (e) {
      log('❌ Error deleting employee: $e');
      return false;
    }
  }

  // ==================== PERMISSIONS & USER DATA ====================

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(
    String username,
    String userType,
  ) async {
    try {
      final collection = userType == kUserTypeManager
          ? kManagersCollection
          : kEmployeesCollection;

      final userDoc = await _firestore
          .collection(collection)
          .doc(username) // Note: This assumes doc ID is username for managers
          .get();

      if (!userDoc.exists) {
        // Fallback: search by username field if doc ID check fails
        final query = await _firestore
            .collection(collection)
            .where(kEmployeeUsername, isEqualTo: username)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          return query.docs.first.data();
        }
        return null;
      }

      return userDoc.data();
    } catch (e) {
      log('❌ Error getting user data: $e');
      return null;
    }
  }

  /// Check if employee has specific permission
  Future<bool> hasPermission(String permissionKey) async {
    try {
      final userType = CacheHelper.getData(kUserType);

      // Managers have all permissions
      if (userType == kUserTypeManager) {
        return true;
      }

      // Get permissions from local storage
      final permissionsJson = CacheHelper.getData('Permissions');
      if (permissionsJson == null) {
        return false;
      }

      // Handle the string format stored in SharedPrefs
      // Note: A more robust JSON parsing might be needed depending on how it's saved
      return permissionsJson.contains(permissionKey);
    } catch (e) {
      log('❌ Error checking permission: $e');
      return false;
    }
  }

  // ==================== MANAGER CREDENTIALS ====================

  /// Update manager credentials/config in Firestore
  /// Includes URLs and optional work location
  Future<void> updateManagerCredentials({
    required String username,
    required String spreadsheetId,
    required String driveFolderId,
    required String appScriptUrl,
    double? workLatitude,
    double? workLongitude,
  }) async {
    try {
      log('📝 Updating credentials for manager: $username');

      final data = <String, dynamic>{
        kManagerSpreadsheetId: spreadsheetId,
        kManagerDriveFolderId: driveFolderId,
        kManagerAppScriptUrl: appScriptUrl,
      };

      // Add work location map if provided
      if (workLatitude != null && workLongitude != null) {
        data[kManagerWorkLocation] = {
          kWorkLatitude: workLatitude,
          kWorkLongitude: workLongitude,
        };
      }

      // Update Firestore (Querying by username field)
      final querySnapshot = await _firestore
          .collection(kManagersCollection)
          .where(kEmployeeUsername, isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Manager document not found for username: $username');
      }

      final docId = querySnapshot.docs.first.id;
      await _firestore.collection(kManagersCollection).doc(docId).update(data);

      // Update SharedPreferences for URLs (using CacheHelper instead of SecureStorage
      // to avoid race conditions in release builds with EncryptedSharedPreferences)
      await CacheHelper.saveData(kSpreadsheetId, spreadsheetId);
      await CacheHelper.saveData(kDriveFolderId, driveFolderId);
      await CacheHelper.saveData(kAppScriptUrl, appScriptUrl);

      // Save work location to SharedPrefs for quick loading
      if (workLatitude != null && workLongitude != null) {
        await CacheHelper.saveData(kPrefWorkLatitude, workLatitude);
        await CacheHelper.saveData(kPrefWorkLongitude, workLongitude);
      }

      log('✅ Credentials updated successfully');
    } catch (e) {
      log('❌ Error updating credentials: $e');
      rethrow;
    }
  }

  /// Get manager credentials (3 URLs) by email
  /// Returns null if manager not found or credentials are incomplete
  Future<Map<String, String>?> getManagerCredentialsByEmail(
    String managerEmail,
  ) async {
    try {
      log('📡 Fetching manager credentials for: $managerEmail');

      final managerDoc = await _firestore
          .collection(kManagersCollection)
          .doc(managerEmail)
          .get();

      if (!managerDoc.exists) {
        log('❌ Manager not found: $managerEmail');
        return null;
      }

      final data = managerDoc.data()!;
      final spreadsheetId = data[kManagerSpreadsheetId] as String?;
      final driveFolderId = data[kManagerDriveFolderId] as String?;
      final appScriptUrl = data[kManagerAppScriptUrl] as String?;

      // Check if all 3 URLs exist and are not empty
      if (spreadsheetId == null ||
          spreadsheetId.isEmpty ||
          driveFolderId == null ||
          driveFolderId.isEmpty ||
          appScriptUrl == null ||
          appScriptUrl.isEmpty) {
        log('⚠️ Manager credentials incomplete');
        return null;
      }

      log('✅ Manager credentials found');
      return {
        kSpreadsheetId: spreadsheetId,
        kDriveFolderId: driveFolderId,
        kAppScriptUrl: appScriptUrl,
      };
    } catch (e) {
      log('❌ Error fetching manager credentials: $e');
      return null;
    }
  }

  /// Register a new manager
  Future<void> registerManager({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      log('📝 Registering new manager: $username');

      // Check if username already exists
      final usernameQuery = await _firestore
          .collection(kManagersCollection)
          .where(kEmployeeUsername, isEqualTo: username)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Username already taken');
      }

      // Check if email already exists
      // Note: Since we use email as Doc ID for managers (per image), we can check doc existence too
      final emailDoc = await _firestore
          .collection(kManagersCollection)
          .doc(email)
          .get();

      if (emailDoc.exists) {
        throw Exception('Email already registered');
      }

      final data = {
        kEmployeeUsername: username,
        kManagerEmail: email,
        kEmployeePassword: password,
        kEmployeeDisplayName: username,
        kEmployeeIsActive: false, // Default to inactive
        kManagerCreatedAt: FieldValue.serverTimestamp(),
        kManagerSpreadsheetId: "",
        kManagerDriveFolderId: "",
        kManagerAppScriptUrl: "",
      };

      // Set document ID as Email (matches your image structure)
      await _firestore.collection(kManagersCollection).doc(email).set(data);
      log('✅ Manager registered successfully (inactive)');
    } catch (e) {
      log('❌ Registration error: $e');
      rethrow;
    }
  }

  // ==================== LOGOUT & SESSION ====================

  /// Logout user - clears all cached session data
  Future<void> logout() async {
    try {
      // Clear all SharedPreferences data to ensure complete logout
      await CacheHelper.clear();

      log('✅ Logout successful - all cache cleared');
    } catch (e) {
      log('❌ Logout error: $e');
    }
  }

  /// Check if current employee is checked in for today
  Future<bool> isEmployeeCheckedIn(String employeeId) async {
    try {
      final doc = await _firestore
          .collection(kEmployeesCollection)
          .doc(employeeId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null || data[kAttendance] == null) return false;

      final attendance = Map<String, dynamic>.from(data[kAttendance]);
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (attendance.containsKey(today)) {
        final todayData = attendance[today];
        final hasCheckIn = todayData[kCheckInTime] != null;
        final hasCheckOut = todayData[kCheckOutTime] != null;
        return hasCheckIn && !hasCheckOut;
      }

      return false;
    } catch (e) {
      log('❌ Error checking attendance: $e');
      return false;
    }
  }

  /// Get current username
  String? getUsername() {
    return CacheHelper.getData(kUsername);
  }
}
