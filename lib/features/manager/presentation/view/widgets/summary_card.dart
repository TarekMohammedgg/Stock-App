import 'dart:async';
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subValue;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.subValue,
    required this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap ?? () {},
      child: Card(
        margin: const EdgeInsets.all(8),
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              isLoading
                  ? _AnimatedDotsText(color: colorScheme.onSurface)
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
              if (subValue != null && !isLoading) ...[
                const SizedBox(height: 2),
                Text(
                  subValue!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.primary.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated dots widget that cycles: "." -> ".." -> "..."
class _AnimatedDotsText extends StatefulWidget {
  final Color color;
  const _AnimatedDotsText({required this.color});

  @override
  State<_AnimatedDotsText> createState() => _AnimatedDotsTextState();
}

class _AnimatedDotsTextState extends State<_AnimatedDotsText> {
  int _dotCount = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount % 3) + 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '.' * _dotCount,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: widget.color,
        letterSpacing: 2,
      ),
    );
  }
}
