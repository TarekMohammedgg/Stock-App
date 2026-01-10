// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:gdrive_tutorial/core/theme_provider.dart';

// /// A widget that displays a theme toggle button
// /// Can be used in AppBar or Settings screen
// class ThemeToggleButton extends StatelessWidget {
//   final bool showLabel;
//   final IconData? lightIcon;
//   final IconData? darkIcon;

//   const ThemeToggleButton({
//     super.key,
//     this.showLabel = false,
//     this.lightIcon,
//     this.darkIcon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ThemeProvider>(
//       builder: (context, themeProvider, _) {
//         final isDark = themeProvider.isDarkMode;

//         if (showLabel) {
//           return TextButton.icon(
//             onPressed: () => themeProvider.toggleTheme(),
//             icon: Icon(
//               isDark
//                   ? (lightIcon ?? Icons.light_mode)
//                   : (darkIcon ?? Icons.dark_mode),
//             ),
//             label: Text(isDark ? 'Light Mode' : 'Dark Mode'),
//           );
//         }

//         return IconButton(
//           onPressed: () => themeProvider.toggleTheme(),
//           icon: AnimatedSwitcher(
//             duration: const Duration(milliseconds: 300),
//             transitionBuilder: (child, animation) {
//               return RotationTransition(
//                 turns: animation,
//                 child: FadeTransition(opacity: animation, child: child),
//               );
//             },
//             child: Icon(
//               isDark
//                   ? (lightIcon ?? Icons.light_mode)
//                   : (darkIcon ?? Icons.dark_mode),
//               key: ValueKey(isDark),
//             ),
//           ),
//           tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
//         );
//       },
//     );
//   }
// }

// /// A widget that displays a theme toggle switch
// /// Useful for settings screens
// class ThemeToggleSwitch extends StatelessWidget {
//   final String? title;
//   final String? subtitle;

//   const ThemeToggleSwitch({super.key, this.title, this.subtitle});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ThemeProvider>(
//       builder: (context, themeProvider, _) {
//         return SwitchListTile(
//           title: Text(title ?? 'Dark Mode'),
//           subtitle: subtitle != null ? Text(subtitle!) : null,
//           value: themeProvider.isDarkMode,
//           onChanged: (value) => themeProvider.setDarkMode(value),
//           secondary: Icon(
//             themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
//           ),
//         );
//       },
//     );
//   }
// }

// /// A widget that displays theme selection with radio buttons
// /// Shows Light, Dark, and System options
// class ThemeSelector extends StatelessWidget {
//   const ThemeSelector({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ThemeProvider>(
//       builder: (context, themeProvider, _) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 'Theme Mode',
//                 style: Theme.of(context).textTheme.titleLarge,
//               ),
//             ),
//             RadioListTile<ThemeMode>(
//               title: const Text('Light'),
//               subtitle: const Text('Always use light theme'),
//               value: ThemeMode.light,
//               groupValue: themeProvider.themeMode,
//               onChanged: (value) {
//                 if (value != null) themeProvider.setThemeMode(value);
//               },
//               secondary: const Icon(Icons.light_mode),
//             ),
//             RadioListTile<ThemeMode>(
//               title: const Text('Dark'),
//               subtitle: const Text('Always use dark theme'),
//               value: ThemeMode.dark,
//               groupValue: themeProvider.themeMode,
//               onChanged: (value) {
//                 if (value != null) themeProvider.setThemeMode(value);
//               },
//               secondary: const Icon(Icons.dark_mode),
//             ),
//             RadioListTile<ThemeMode>(
//               title: const Text('System'),
//               subtitle: const Text('Follow system theme'),
//               value: ThemeMode.system,
//               groupValue: themeProvider.themeMode,
//               onChanged: (value) {
//                 if (value != null) themeProvider.setThemeMode(value);
//               },
//               secondary: const Icon(Icons.brightness_auto),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
