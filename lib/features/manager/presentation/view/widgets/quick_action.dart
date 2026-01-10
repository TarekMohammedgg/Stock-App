import 'dart:ui';

import 'package:flutter/material.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.primary,
            child: Icon(icon, color: colorScheme.onPrimary, size: 30),
          ),
        ),
        const SizedBox(height: 5),
        Text(label),
      ],
    );
  }
}
