// lib/core/initialization/app_initializer.dart

import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/helper.dart';
import 'package:gdrive_tutorial/core/internet_connectino_helper.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/login_selection_screen.dart';
import 'package:gdrive_tutorial/features/employee/presentation/view/employee_screen.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/manager_screen.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/credential_screen.dart';
import 'package:gdrive_tutorial/features/onboarding/presentation/views/onboarding_screen.dart';
import 'package:gdrive_tutorial/firebase_options.dart';

enum InitializationStep {
  firebase,
  cache,
  environment,
  network,
  deviceInfo,
  credentials,
  complete,
}

/// Result of app initialization containing route and any required data
class InitializationResult {
  final String route;
  final Map<String, dynamic> data;

  const InitializationResult({required this.route, this.data = const {}});

  /// Helper to get username for CredentialScreen
  String? get username => data['username'] as String?;
}

class AppInitializer {
  static InitializationStep currentStep = InitializationStep.firebase;

  /// Returns the initial route and data based on user state
  static Future<InitializationResult> initialize({
    required Function(InitializationStep step, double progress) onProgress,
  }) async {
    try {
      // Step 1: Firebase
      onProgress(InitializationStep.firebase, 0.1);
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Step 2: Cache
      onProgress(InitializationStep.cache, 0.25);
      await CacheHelper.init();

      // Step 3: Environment
      onProgress(InitializationStep.environment, 0.4);
      await dotenv.load(fileName: ".env");

      // Step 4: Network
      onProgress(InitializationStep.network, 0.55);
      NetworkService().initialize();

      // Step 5: Device Info
      onProgress(InitializationStep.deviceInfo, 0.7);
      String deviceNameId = await getDeviceNameID();
      await CacheHelper.saveData(kDeviceInfoNameId, deviceNameId);

      // Step 6: Determine route
      onProgress(InitializationStep.credentials, 0.85);
      final result = await _determineInitialRoute();

      onProgress(InitializationStep.complete, 1.0);

      log('✅ App initialization complete');
      return result;
    } catch (e, stackTrace) {
      log('❌ Initialization error: $e');
      log('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<InitializationResult> _determineInitialRoute() async {
    var isLogin = CacheHelper.getData(kIsLogin);
    if (isLogin == null) {
      await CacheHelper.saveData(kIsLogin, false);
      isLogin = false;
    }

    final hasSeenOnboarding = CacheHelper.getData(kIsShowOnboarding) ?? false;

    if (!hasSeenOnboarding) {
      return InitializationResult(route: OnboardingScreen.id);
    }

    if (isLogin == true) {
      final userType = CacheHelper.getData(kUserType);

      if (userType == kUserTypeManager) {
        final spreadsheetId = CacheHelper.getData(kSpreadsheetId) as String?;
        final folderId = CacheHelper.getData(kDriveFolderId) as String?;
        final appScriptUrl = CacheHelper.getData(kAppScriptUrl) as String?;

        if (spreadsheetId == null ||
            spreadsheetId.isEmpty ||
            folderId == null ||
            folderId.isEmpty ||
            appScriptUrl == null ||
            appScriptUrl.isEmpty) {
          // Get username from cache for CredentialScreen
          final username = CacheHelper.getData(kUsername) ?? '';
          return InitializationResult(
            route: CredentialScreen.id,
            data: {'username': username},
          );
        }
        return InitializationResult(route: ManagerScreen.id);
      } else if (userType == kUserTypeEmployee) {
        return InitializationResult(route: EmployeeScreen.id);
      }
    }

    return InitializationResult(route: LoginSelectionScreen.id);
  }
}
