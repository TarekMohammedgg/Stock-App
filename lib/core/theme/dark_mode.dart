import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.dark(
    background: const Color(0xFF121212),
    onBackground: Colors.white,
    primary: const Color(0xFF82B1FF),
    onPrimary: const Color(0xFF121212),
    secondary: const Color(0xFF81C784),
    onSecondary: const Color(0xFF121212),
    surface: const Color(0xFF1E1E1E),
    onSurface: Colors.white,
    tertiary: const Color(0xFF1E1E1E),
    // InversePrimary: Main Text Color (White)
    inversePrimary: Colors.grey.shade100,
  ),
);
