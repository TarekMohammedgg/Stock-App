// import 'package:flutter/material.dart';
// import 'package:gdrive_tutorial/core/shared_prefs.dart';
// import 'package:gdrive_tutorial/core/consts.dart';

// /// Theme provider using ChangeNotifier for state management
// /// Manages dark/light theme mode and persists user preference
// class ThemeProvider extends ChangeNotifier {
//   ThemeMode _themeMode = ThemeMode.light;
//   bool _isInitialized = false;

//   ThemeMode get themeMode => _themeMode;
//   bool get isDarkMode => _themeMode == ThemeMode.dark;
//   bool get isInitialized => _isInitialized;

//   /// Initialize theme from shared preferences
//   Future<void> initialize() async {
//     if (_isInitialized) return;

//     final isDark = CacheHelper.getData(kThemeMode) ?? false;
//     _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
//     _isInitialized = true;
//     notifyListeners();
//   }

//   /// Toggle between dark and light theme
//   Future<void> toggleTheme() async {
//     _themeMode = _themeMode == ThemeMode.light
//         ? ThemeMode.dark
//         : ThemeMode.light;
//     await CacheHelper.saveData(kThemeMode, _themeMode == ThemeMode.dark);
//     notifyListeners();
//   }

//   /// Set theme mode explicitly
//   Future<void> setThemeMode(ThemeMode mode) async {
//     if (_themeMode == mode) return;

//     _themeMode = mode;
//     await CacheHelper.saveData(kThemeMode, mode == ThemeMode.dark);
//     notifyListeners();
//   }

//   /// Set dark mode
//   Future<void> setDarkMode(bool isDark) async {
//     await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
//   }
// }
