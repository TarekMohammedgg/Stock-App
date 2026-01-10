import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:gdrive_tutorial/core/app_theme.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/manager_screen.dart';
import 'package:gdrive_tutorial/services/firestore_auth_service.dart';

class CredentialScreen extends StatefulWidget {
  static const String id = 'credential_screen';
  final String username;

  const CredentialScreen({super.key, required this.username});

  @override
  State<CredentialScreen> createState() => _CredentialScreenState();
}

class _CredentialScreenState extends State<CredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = FirestoreAuthService();

  final _spreadsheetUrlController = TextEditingController();
  final _folderUrlController = TextEditingController();
  final _appScriptUrlController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _spreadsheetUrlController.dispose();
    _folderUrlController.dispose();
    _appScriptUrlController.dispose();
    super.dispose();
  }

  String? _extractSpreadsheetId(String url) {
    // Format: https://docs.google.com/spreadsheets/d/SPREADSHEET_ID/edit#gid=0
    final regExp = RegExp(r'/d/([a-zA-Z0-9-_]+)');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  String? _extractFolderId(String url) {
    // Format: https://drive.google.com/drive/folders/FOLDER_ID
    final regExp = RegExp(r'folders/([a-zA-Z0-9-_]+)');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final spreadsheetUrl = _spreadsheetUrlController.text.trim();
    final folderUrl = _folderUrlController.text.trim();
    final appScriptUrl = _appScriptUrlController.text.trim();

    final spreadsheetId = _extractSpreadsheetId(spreadsheetUrl);
    final folderId = _extractFolderId(folderUrl);

    if (spreadsheetId == null) {
      _showError('Could not extract Spreadsheet ID from URL'.tr());
      return;
    }

    if (folderId == null) {
      _showError('Could not extract Folder ID from URL'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.updateManagerCredentials(
        username: widget.username,
        spreadsheetId: spreadsheetId,
        driveFolderId: folderId,
        appScriptUrl: appScriptUrl,
      );

      if (!mounted) return;

      // Navigate to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ManagerScreen()),
      );
    } catch (e) {
      _showError('${'Failed to save credentials'.tr()}: $e');
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
        title: Text('Service Setup'.tr()),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.settings_suggest_rounded,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Complete Setup'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your Google service URLs to connect your inventory system.'
                    .tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                controller: _spreadsheetUrlController,
                label: 'Google Spreadsheet URL'.tr(),
                hint: 'https://docs.google.com/spreadsheets/d/...',
                icon: Icons.table_chart_rounded,
                colorScheme: colorScheme,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _folderUrlController,
                label: 'Google Drive Folder URL'.tr(),
                hint: 'https://drive.google.com/drive/folders/...',
                icon: Icons.folder_rounded,
                colorScheme: colorScheme,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _appScriptUrlController,
                label: 'App Script API URL'.tr(),
                hint: 'https://script.google.com/macros/s/.../exec',
                icon: Icons.api_rounded,
                colorScheme: colorScheme,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required'.tr();
                  if (!v!.startsWith('https://script.google.com')) {
                    return 'Invalid App Script URL'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          'Save & Continue'.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
                child: Text(
                  'Back to Login'.tr(),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: colorScheme.onBackground),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.primary.withOpacity(0.8)),
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.onBackground.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: validator,
    );
  }
}
