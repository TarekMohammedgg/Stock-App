// lib/features/initialization/presentation/views/initialization_screen.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gdrive_tutorial/core/initialization/app_initializer.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/credential_screen.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _progress = 0.0;
  String _statusMessage = 'Starting...';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final result = await AppInitializer.initialize(
        onProgress: (step, progress) {
          if (!mounted) return;
          setState(() {
            _progress = progress;
            _statusMessage = _getStepMessage(step);
          });
        },
      );

      if (!mounted) return;

      // Navigate based on the result
      // Special handling for CredentialScreen which needs username parameter
      if (result.route == CredentialScreen.id) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CredentialScreen(username: result.username ?? ''),
          ),
        );
      } else {
        // Use named routes for other screens
        Navigator.of(context).pushReplacementNamed(result.route);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  String _getStepMessage(InitializationStep step) {
    switch (step) {
      case InitializationStep.firebase:
        return 'Connecting to services...';
      case InitializationStep.cache:
        return 'Loading preferences...';
      case InitializationStep.environment:
        return 'Configuring environment...';
      case InitializationStep.network:
        return 'Checking connectivity...';
      case InitializationStep.deviceInfo:
        return 'Identifying device...';
      case InitializationStep.credentials:
        return 'Verifying credentials...';
      case InitializationStep.complete:
        return 'Ready!';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Color(0xff271552),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/stock-logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 48),

              if (_hasError) ...[
                // Error State
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Initialization Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onBackground),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _progress = 0;
                    });
                    _initializeApp();
                  },
                  child: const Text('Retry'),
                ),
              ] else ...[
                // Loading State
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Message
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: colorScheme.onBackground.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Percentage
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
