import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  // Location controllers
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _spreadsheetUrlController.dispose();
    _folderUrlController.dispose();
    _appScriptUrlController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  /// Get current GPS location and populate the text fields
  Future<void> _getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Use default location if permission denied
        setState(() {
          _latitudeController.text = '30.044420';
          _longitudeController.text = '31.235712';
          _isLoadingLocation = false;
        });
        _showError('Location permission denied. Using default location.'.tr());
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
        _isLoadingLocation = false;
      });
    } catch (e) {
      // Fallback to default location
      setState(() {
        _latitudeController.text = '30.044420';
        _longitudeController.text = '31.235712';
        _isLoadingLocation = false;
      });
    }
  }

  /// Refresh location from GPS
  Future<void> _refreshLocation() async {
    setState(() => _isLoadingLocation = true);
    await _getCurrentLocation();
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

    // Parse location values
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

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

    if (latitude == null || longitude == null) {
      _showError('Invalid latitude or longitude values'.tr());
      return;
    }

    // Validate coordinate ranges
    if (latitude < -90 || latitude > 90) {
      _showError('Latitude must be between -90 and 90'.tr());
      return;
    }

    if (longitude < -180 || longitude > 180) {
      _showError('Longitude must be between -180 and 180'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.updateManagerCredentials(
        username: widget.username,
        spreadsheetId: spreadsheetId,
        driveFolderId: folderId,
        appScriptUrl: appScriptUrl,
        workLatitude: latitude,
        workLongitude: longitude,
      );

      if (!mounted) return;

      // Navigate to Manager Screen - clear entire navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ManagerScreen()),
        (route) => false,
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
                'Enter your Google service URLs and work location.'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),

              // ========== URL FIELDS ==========
              _buildTextField(
                controller: _spreadsheetUrlController,
                label: 'Google Spreadsheet URL'.tr(),
                hint: 'https://docs.google.com/spreadsheets/d/...',
                icon: Icons.table_chart_rounded,
                colorScheme: colorScheme,
                validator: (v) => v?.isEmpty ?? true ? 'Required'.tr() : null,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _folderUrlController,
                label: 'Google Drive Folder URL'.tr(),
                hint: 'https://drive.google.com/drive/folders/...',
                icon: Icons.folder_rounded,
                colorScheme: colorScheme,
                validator: (v) => v?.isEmpty ?? true ? 'Required'.tr() : null,
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
              const SizedBox(height: 32),

              // ========== WORK LOCATION SECTION ==========
              _buildLocationSection(colorScheme),

              const SizedBox(height: 48),

              // ========== SAVE BUTTON ==========
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

  /// Build the Work Location section with lat/lng text fields
  Widget _buildLocationSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.location_on, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Work Location'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              // Refresh location button
              if (_isLoadingLocation)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              else
                IconButton(
                  onPressed: _refreshLocation,
                  icon: Icon(Icons.my_location, color: colorScheme.primary),
                  tooltip: 'Get Current Location'.tr(),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your current location is auto-detected. You can edit it manually.'
                .tr(),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),

          // Latitude and Longitude fields in a row
          Row(
            children: [
              Expanded(
                child: _buildCoordinateField(
                  controller: _latitudeController,
                  label: 'Latitude'.tr(),
                  hint: '30.044420',
                  colorScheme: colorScheme,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required'.tr();
                    final val = double.tryParse(v!);
                    if (val == null) return 'Invalid'.tr();
                    if (val < -90 || val > 90) return '-90 to 90'.tr();
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCoordinateField(
                  controller: _longitudeController,
                  label: 'Longitude'.tr(),
                  hint: '31.235712',
                  colorScheme: colorScheme,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required'.tr();
                    final val = double.tryParse(v!);
                    if (val == null) return 'Invalid'.tr();
                    if (val < -180 || val > 180) return '-180 to 180'.tr();
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a coordinate input field
  Widget _buildCoordinateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ColorScheme colorScheme,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      style: TextStyle(color: colorScheme.onBackground),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.primary.withOpacity(0.8)),
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.onBackground.withOpacity(0.4)),
        filled: true,
        fillColor: colorScheme.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: validator,
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
