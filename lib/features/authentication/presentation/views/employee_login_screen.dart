import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:gdrive_tutorial/core/app_theme.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/secure_storage_helper.dart';
import 'package:gdrive_tutorial/features/employee/presentation/view/employee_screen.dart';
import 'package:gdrive_tutorial/services/firestore_auth_service.dart';

/// Employee login screen with username/password
class EmployeeLoginScreen extends StatefulWidget {
  static const String id = 'employee_login_screen';
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
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
        userType: kUserTypeEmployee,
      );

      if (!mounted) return;

      if (result != null) {
        // First check if credentials exist in prefs
        final prefSpreadsheetId = await SecureStorageHelper.read(
          kSpreadsheetId,
        );
        final prefFolderId = await SecureStorageHelper.read(kDriveFolderId);
        final prefAppScriptUrl = await SecureStorageHelper.read(kAppScriptUrl);

        final hasPrefsCredentials =
            prefSpreadsheetId != null &&
            prefSpreadsheetId.isNotEmpty &&
            prefFolderId != null &&
            prefFolderId.isNotEmpty &&
            prefAppScriptUrl != null &&
            prefAppScriptUrl.isNotEmpty;

        if (!hasPrefsCredentials) {
          // Prefs don't have credentials - fetch from manager's Firebase collection
          final managerEmail = result[kEmployeeManagerEmail] as String?;

          if (managerEmail == null || managerEmail.isEmpty) {
            _showError('Manager email not found for this employee'.tr());
            return;
          }

          log('📡 Fetching credentials from manager: $managerEmail');

          // Fetch manager's credentials
          final managerCredentials = await _authService
              .getManagerCredentialsByEmail(managerEmail);

          if (managerCredentials != null) {
            // Save manager's credentials to employee's prefs
            await SecureStorageHelper.write(
              kSpreadsheetId,
              managerCredentials[kSpreadsheetId]!,
            );
            await SecureStorageHelper.write(
              kDriveFolderId,
              managerCredentials[kDriveFolderId]!,
            );
            await SecureStorageHelper.write(
              kAppScriptUrl,
              managerCredentials[kAppScriptUrl]!,
            );
            log('✅ Manager credentials saved to employee prefs');
          } else {
            // Manager doesn't have credentials set up
            if (!mounted) return;
            _showError(
              'Your manager has not set up the required credentials yet. Please contact your manager.'
                  .tr(),
            );
            return;
          }
        }

        // Navigate to employee screen
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeScreen()),
        );
      } else {
        _showError('Invalid username or password'.tr());
      }
    } catch (e) {
      log('Employee login error: $e');
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
        title: Text('Employee Login'.tr()),
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
                  // Employee Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Employee Access'.tr(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with your credentials'.tr(),
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
                              "Contact your manager if you don't have login credentials."
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
