import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gdrive_tutorial/core/theme/toggle_theme.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/employee_login_screen.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/manager_login_screen.dart';
import 'package:provider/provider.dart';

/// Initial screen where user selects login type
class LoginSelectionScreen extends StatelessWidget {
  static const String id = 'login_selection_screen';
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: const Text('Stock Management').tr(),
        actions: [
          // The Language Selector Box
          DropdownButton<Locale>(
            underline: const SizedBox(),
            icon: Padding(
              padding: EdgeInsets.only(
                left: context.locale.languageCode == 'ar' ? 0 : 10,
              ),
              child: Icon(
                Icons.language,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            dropdownColor: Theme.of(context).colorScheme.primary,
            value: context.locale,

            items: context.supportedLocales.map((Locale locale) {
              return DropdownMenuItem<Locale>(
                value: locale,
                child: Text(
                  _getLanguageName(locale.languageCode),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
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

          IconButton(
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            icon: Icon(
              Provider.of<ThemeProvider>(context, listen: true).isDark
                  ? Icons.mode_night_outlined
                  : Icons.sunny,
              color: colorScheme.inversePrimary,
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Image.asset("assets/images/login/welcome.png"),
              const SizedBox(height: 32),

              // Welcome Text
              Text(
                'Welcome',
                style: Theme.of(context).textTheme.headlineLarge,
              ).tr(),
              const SizedBox(height: 8),
              Text(
                'Choose your login method',
                style: Theme.of(context).textTheme.bodyLarge,
              ).tr(),
              const SizedBox(height: 48),

              // Manager Login Button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: colorScheme.onPrimary,
                  ),
                  title: Text(
                    'Manager Login',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ).tr(),
                  subtitle: Text(
                    'Sign in with username & password',
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ).tr(),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: colorScheme.onPrimary,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManagerLoginScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Employee Login Button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.person,
                    size: 40,
                    color: colorScheme.onPrimary,
                  ),
                  title: Text(
                    'Employee Login',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ).tr(),
                  subtitle: Text(
                    'Sign in with username & password',
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ).tr(),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: colorScheme.onPrimary,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmployeeLoginScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'en':
      default:
        return 'English';
    }
  }
}
