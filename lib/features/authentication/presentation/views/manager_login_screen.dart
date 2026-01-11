import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:gdrive_tutorial/core/app_theme.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/manager_screen.dart';
import 'package:gdrive_tutorial/services/firestore_auth_service.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/credential_screen.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/manager_signup_screen.dart';

/// Manager login screen with username/password authentication
class ManagerLoginScreen extends StatefulWidget {
  static const String id = 'manager_login_screen';
  const ManagerLoginScreen({super.key});

  @override
  State<ManagerLoginScreen> createState() => _ManagerLoginScreenState();
}

class _ManagerLoginScreenState extends State<ManagerLoginScreen> {
  final FirestoreAuthService _authService = FirestoreAuthService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.loginUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        userType: kUserTypeManager,
      );

      if (!mounted) return;

      if (result != null) {
        // Check if credentials exist in Firebase result
        final spreadsheetId = result[kManagerSpreadsheetId]?.toString() ?? '';
        final driveFolderId = result[kManagerDriveFolderId]?.toString() ?? '';
        final appScriptUrl = result[kManagerAppScriptUrl]?.toString() ?? '';

        final hasAllCredentials =
            spreadsheetId.isNotEmpty &&
            driveFolderId.isNotEmpty &&
            appScriptUrl.isNotEmpty;

        if (hasAllCredentials) {
          // Firebase has credentials - check if they're in prefs
          final prefSpreadsheetId =
              CacheHelper.getData(kSpreadsheetId) as String?;
          final prefFolderId = CacheHelper.getData(kDriveFolderId) as String?;
          final prefAppScriptUrl =
              CacheHelper.getData(kAppScriptUrl) as String?;

          // Sync to prefs if not already there or different
          if (prefSpreadsheetId != spreadsheetId ||
              prefFolderId != driveFolderId ||
              prefAppScriptUrl != appScriptUrl) {
            log('📥 Syncing Firebase credentials to SharedPreferences...');
            await CacheHelper.saveData(kSpreadsheetId, spreadsheetId);
            await CacheHelper.saveData(kDriveFolderId, driveFolderId);
            await CacheHelper.saveData(kAppScriptUrl, appScriptUrl);
            log('✅ Credentials synced to SharedPreferences');
          }

          // Navigate to home screen - clear entire navigation stack
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ManagerScreen()),
            (route) => false, // Remove all previous routes
          );
        } else {
          // Firebase doesn't have credentials - check prefs as fallback
          final prefSpreadsheetId =
              CacheHelper.getData(kSpreadsheetId) as String?;
          final prefFolderId = CacheHelper.getData(kDriveFolderId) as String?;
          final prefAppScriptUrl =
              CacheHelper.getData(kAppScriptUrl) as String?;

          final hasPrefsCredentials =
              prefSpreadsheetId != null &&
              prefSpreadsheetId.isNotEmpty &&
              prefFolderId != null &&
              prefFolderId.isNotEmpty &&
              prefAppScriptUrl != null &&
              prefAppScriptUrl.isNotEmpty;

          if (!mounted) return;

          if (hasPrefsCredentials) {
            // Has credentials in prefs, navigate to home - clear stack
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ManagerScreen()),
              (route) => false,
            );
          } else {
            // No credentials anywhere - navigate to credential setup
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CredentialScreen(username: _usernameController.text.trim()),
              ),
              (route) => false,
            );
          }
        }
      } else {
        _showError('Invalid username or password'.tr());
      }
    } catch (e) {
      log('Manager login error: $e');
      if (mounted) {
        _showError(
          e.toString().contains('inactive')
              ? e.toString().replaceAll('Exception: ', '')
              : 'An error occurred during login'.tr(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text('Manager Login'.tr()),
        elevation: 0,
        foregroundColor: colorScheme.primary,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Manager Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Manager Access'.tr(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with your credentials to manage\\nyour inventory and employees'
                        .tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Username'.tr(),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password'.tr(),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: colorScheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              'Login'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your account must be registered in the system to login.'
                                  .tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onBackground.withOpacity(
                                  0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have a manager account?".tr()),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManagerSignUpScreen(),
                            ),
                          );
                        },
                        child: Text('Sign Up'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
