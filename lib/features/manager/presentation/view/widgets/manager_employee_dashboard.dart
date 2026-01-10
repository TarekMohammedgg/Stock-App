import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:gdrive_tutorial/core/app_theme.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/services/firestore_auth_service.dart';

/// Manager dashboard for employee management
class ManagerEmployeeDashboard extends StatefulWidget {
  static const String id = 'ManagerEmployeeDashboard';
  const ManagerEmployeeDashboard({super.key});

  @override
  State<ManagerEmployeeDashboard> createState() =>
      _ManagerEmployeeDashboardState();
}

class _ManagerEmployeeDashboardState extends State<ManagerEmployeeDashboard> {
  final FirestoreAuthService _employeeService = FirestoreAuthService();
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);

    final managerEmail = CacheHelper.getData('Email');
    print('🔍 Manager email from cache: $managerEmail');

    if (managerEmail == null) {
      print('❌ No manager email found in cache');
      setState(() => _isLoading = false);
      return;
    }

    print('📞 Calling getEmployees for: $managerEmail');
    final employees = await _employeeService.getEmployees(managerEmail);
    print('✅ Received ${employees.length} employees');

    if (mounted) {
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    }
  }

  void _showAddEmployeeDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final displayNameController = TextEditingController();
    String? usernameError; // Local variable to track database error

    final permissions = {
      'canAddProducts': true,
      'canDeleteProducts': false,
      'canViewAnalytics': false,
      'canManageInventory': true,
    };

    Timer? debounce;
    bool isChecking = false;

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: colorScheme.surface,
            title: Text(
              'Add New Employee',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        prefixIcon: Icon(
                          Icons.person,
                          color: colorScheme.primary,
                        ),
                        errorText: usernameError,
                        suffixIcon: isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      onChanged: (v) {
                        if (debounce?.isActive ?? false) debounce?.cancel();

                        if (v.isEmpty) {
                          setDialogState(() {
                            usernameError = null;
                            isChecking = false;
                          });
                          return;
                        }

                        setDialogState(() => isChecking = true);

                        debounce = Timer(
                          const Duration(milliseconds: 500),
                          () async {
                            final isTaken = await _employeeService
                                .isUsernameTaken(v.trim());
                            setDialogState(() {
                              isChecking = false;
                              if (isTaken) {
                                usernameError =
                                    "the user name is already in employees";
                              } else {
                                usernameError = null;
                              }
                            });
                          },
                        );
                      },
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        prefixIcon: Icon(
                          Icons.lock,
                          color: colorScheme.primary,
                        ),
                      ),
                      obscureText: true,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (v!.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: displayNameController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        labelStyle: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        prefixIcon: Icon(
                          Icons.badge,
                          color: colorScheme.primary,
                        ),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Permissions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    ...permissions.keys.map((key) {
                      return CheckboxListTile(
                        title: Text(
                          _formatPermissionName(key),
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        value: permissions[key],
                        activeColor: colorScheme.primary,
                        checkColor: colorScheme.onPrimary,
                        onChanged: (value) {
                          setDialogState(() {
                            permissions[key] = value ?? false;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                onPressed: (isChecking || usernameError != null)
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        final managerEmail = CacheHelper.getData(kEmail);
                        if (managerEmail == null) return;

                        Navigator.pop(context);

                        final success = await _employeeService.createEmployee(
                          username: usernameController.text.trim(),
                          password: passwordController.text,
                          displayName: displayNameController.text.trim(),
                          managerEmail: managerEmail,
                          roles: ['employee'],
                          permissions: permissions,
                        );

                        if (success) {
                          _showSnackBar(
                            'Employee added successfully',
                            isError: false,
                          );
                          _loadEmployees();
                        } else {
                          _showSnackBar(
                            'Failed to add employee',
                            isError: true,
                          );
                        }
                      },
                child: const Text('Add Employee'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatPermissionName(String key) {
    return key
        .replaceAll('can', '')
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .trim();
  }

  void _showSnackBar(String message, {required bool isError}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.white : colorScheme.onSecondary,
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : colorScheme.secondary,
      ),
    );
  }

  Future<void> _toggleEmployeeStatus(
    String employeeId,
    bool currentStatus,
  ) async {
    final success = await _employeeService.updateEmployeeStatus(
      employeeId: employeeId,
      isActive: !currentStatus,
    );

    if (success) {
      _showSnackBar(
        currentStatus ? 'Employee deactivated' : 'Employee activated',
        isError: false,
      );
      _loadEmployees();
    } else {
      _showSnackBar('Failed to update status', isError: true);
    }
  }

  Future<void> _deleteEmployee(String employeeId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete "$username"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _employeeService.deleteEmployee(employeeId);

    if (success) {
      _showSnackBar('Employee deleted', isError: false);
      _loadEmployees();
    } else {
      _showSnackBar('Failed to delete employee', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Employees'.tr(),
          style: TextStyle(
            color: colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEmployees,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
            : _employees.isEmpty
            ? _buildEmptyState()
            : _buildEmployeeList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEmployeeDialog,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: Icon(Icons.person_add, color: colorScheme.onPrimary),
        label: Text(
          'Add Employee'.tr(),
          style: TextStyle(color: colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Employees Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first employee to get started',
            style: TextStyle(color: colorScheme.onBackground.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final employee = _employees[index];
        final isActive = employee[kEmployeeIsActive] ?? false;

        return Card(
          elevation: 2,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Icon(Icons.person, color: colorScheme.primary),
            ),
            title: Text(
              employee[kEmployeeDisplayName] ?? 'Unknown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${employee[kEmployeeUsername]}',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? Colors.green.withOpacity(0.5)
                              : Colors.red.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
              color: colorScheme.surface,
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        size: 20,
                        color: isActive
                            ? Colors.orangeAccent
                            : Colors.greenAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'Deactivate' : 'Activate',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  onTap: () => _toggleEmployeeStatus(employee['id'], isActive),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  onTap: () => _deleteEmployee(
                    employee['id'],
                    employee[kEmployeeUsername],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
