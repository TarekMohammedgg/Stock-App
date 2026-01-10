import 'package:flutter/material.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/core/theme/dark_mode.dart';
import 'package:gdrive_tutorial/core/theme/light_mode.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = lightMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    final bool? isDark = CacheHelper.getData(kThemeMode);
    if (isDark == true) {
      _themeData = darkMode;
    } else {
      _themeData = lightMode;
    }
    notifyListeners();
  }

  ThemeData get themeData => _themeData;

  set themeData(ThemeData theme) {
    _themeData = theme;
    CacheHelper.saveData(kThemeMode, isDark);
    notifyListeners();
  }

  bool get isDark => _themeData == darkMode;

  void toggleTheme() {
    if (themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}
