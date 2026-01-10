import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/helper.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/core/theme/toggle_theme.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/login_selection_screen.dart';
import 'package:provider/provider.dart';

class LogoutScreen extends StatefulWidget {
  static const String id = 'logout_screen';
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  String? email;
  bool isLoading = false;

  Future<void> _logout() async {
    if (mounted) {
      Navigator.pushReplacementNamed(context, LoginSelectionScreen.id);
    }
  }

  Future<void> getEmail() async {
    final res = await CacheHelper.getData(kEmail);
    setState(() {
      email = res;
    });
  }

  @override
  void initState() {
    super.initState();
    getEmail();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Profile'.tr(),
          style: TextStyle(color: colorScheme.onBackground),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image with modern styling
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                // Email Container with modern capsule design
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: colorScheme.onBackground.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        email ?? "manager@stock.com",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Theme Toggle Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.05),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            colorScheme.brightness == Brightness.dark
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Dark Mode".tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      CupertinoSwitch(
                        activeColor: colorScheme.primary,
                        value: Provider.of<ThemeProvider>(
                          context,
                          listen: true,
                        ).isDark,
                        onChanged: (value) {
                          Provider.of<ThemeProvider>(
                            context,
                            listen: false,
                          ).toggleTheme();
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.05),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.language, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            "Language".tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      DropdownButton(
                        value: context.locale,
                        underline: const SizedBox(),
                        items: context.supportedLocales.map((Locale local) {
                          return DropdownMenuItem<Locale>(
                            value: local,
                            child: Text(
                              getLanguageName(local.languageCode),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.inversePrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (Locale? newLocale) {
                          if (newLocale != null) {
                            context.setLocale(newLocale);
                          }
                        },
                      ),
                      // GestureDetector(

                      //   child: Row(
                      //     children: [
                      //       Text(
                      //         context.locale.languageCode.toUpperCase(),
                      //         style: TextStyle(fontSize: 16),
                      //       ),
                      //       Icon(Icons.arrow_drop_down, size: 24),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: isLoading ? null : _logout,
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            "Logout".tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
