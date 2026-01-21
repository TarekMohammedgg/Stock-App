import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/manager_screen.dart';
import 'package:gdrive_tutorial/services/firestore_auth_service.dart';

class ManagerSignUpScreen extends StatefulWidget {
  static const String id = 'manager_signup_screen';
  const ManagerSignUpScreen({super.key});

  @override
  State<ManagerSignUpScreen> createState() => _ManagerSignUpScreenState();
}

class _ManagerSignUpScreenState extends State<ManagerSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = FirestoreAuthService();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.registerManager(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Save minimal data to cache for pending activation state
      await CacheHelper.saveData(kEmail, _emailController.text.trim());
      await CacheHelper.saveData(kUsername, _usernameController.text.trim());
      await CacheHelper.saveData(kDisplayName, _usernameController.text.trim());
      await CacheHelper.saveData(kIsLogin, true);
      await CacheHelper.saveData(kUserType, kUserTypeManager);
      await CacheHelper.saveData(kPrefManagerIsActive, false); // Not active yet

      // Navigate to ManagerScreen (will show pending activation message)
      Navigator.of(context).pushReplacementNamed(ManagerScreen.id);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text('Manager Sign Up'.tr()),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.primary,
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      Icons.person_add_alt_1,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Create Account'.tr(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join as a manager to start managing\\nyour inventory and teams.'
                        .tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Username
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
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Required'.tr() : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Email'.tr(),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required'.tr();
                      if (!v!.contains('@')) return 'Invalid email'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
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
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required'.tr();
                      if (v!.length < 6) return 'Too short (min 6 chars)'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password'.tr(),
                      prefixIcon: Icon(
                        Icons.lock_reset_outlined,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required'.tr();
                      if (v != _passwordController.text)
                        return 'Passwords do not match'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                            )
                          : Text(
                              'Sign Up'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?'.tr()),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Login'.tr()),
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
