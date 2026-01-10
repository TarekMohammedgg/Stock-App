import 'dart:async';
import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/permission_helper.dart';
import 'package:gdrive_tutorial/core/theme/toggle_theme.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/login_selection_screen.dart';
import 'package:gdrive_tutorial/features/employee/presentation/view/widgets/employee_attendance.dart';
import 'package:gdrive_tutorial/services/firestore_auth_service.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/manager_screen.dart';
import 'package:gdrive_tutorial/features/search_products/presentation/view/search_items_screen.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/core/widgets/product_image_widget.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:synchronized/synchronized.dart';

class EmployeeScreen extends StatefulWidget {
  static const String id = 'employee_screen';
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final GSheetService gSheetService = GSheetService();

  // Locks for synchronized operations
  final Lock _transactionLock = Lock();
  final Lock _productListLock = Lock();

  MobileScannerController? scannerController;

  bool isLoading = false;
  bool isScanning = false;

  /// Product loaded from scan or search
  List<Map<String, dynamic>>? selectedProduct;

  @override
  void dispose() {
    scannerController?.dispose();
    super.dispose();
  }

  // =========================
  // Product Operations
  // =========================

  Future<void> _searchItems() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const SearchItemsScreen()),
    );

    if (result != null) {
      await _productListLock.synchronized(() async {
        setState(() {
          selectedProduct ??= [];
          final exists = selectedProduct!.any(
            (p) => p[kProductId] == result[kProductId],
          );
          if (exists) {
            _showErrorSnackBar('Product already added'.tr());
            return;
          }
          result[kSellQuantity] = 0;
          selectedProduct!.add(result);
        });
      });

      _showSuccessSnackBar('${'Item loaded'.tr()}: ${result['Product Name']}');
    }
  }

  Future<void> _addTransaction() async {
    // 1. Check User Type and Attendance
    final authService = FirestoreAuthService();
    final String? employeeId = CacheHelper.getData(kEmployeeId);
    final String? userType = CacheHelper.getData(kUserType);

    if (employeeId == null && userType != kUserTypeManager) {
      _showErrorSnackBar('Session expired. Please login again.'.tr());
      return;
    }

    setState(() => isLoading = true);

    // Managers skip attendance check
    bool shouldCheckAttendance = userType != kUserTypeManager;
    bool isCheckedIn = true;

    if (shouldCheckAttendance && employeeId != null) {
      isCheckedIn = await authService.isEmployeeCheckedIn(employeeId);
    }

    if (!isCheckedIn) {
      setState(() => isLoading = false);
      _showErrorSnackBar('You must check in before making transactions'.tr());
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EmployeeAttendance()),
        );
      }
      return;
    }

    // 2. Check permission
    // For managers, we assume full permission or at least skip the standard check if desired,
    // but the user said "permission is full", so we can either skip or let it pass.
    if (userType != kUserTypeManager) {
      final hasPermission = await PermissionHelper.canManageInventory();
      if (!hasPermission) {
        setState(() => isLoading = false);
        _showErrorSnackBar(
          'You do not have permission to manage inventory'.tr(),
        );
        return;
      }
    }

    if (selectedProduct == null || selectedProduct!.isEmpty) {
      setState(() => isLoading = false);
      _showErrorSnackBar('No products selected'.tr());
      return;
    }

    // Check if at least one product has quantity > 0
    final hasValidQuantity = selectedProduct!.any((product) {
      final sellQty = _parseIntValue(product[kSellQuantity]);
      return sellQty > 0;
    });

    if (!hasValidQuantity) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Please set quantity for at least one product'.tr());
      return;
    }

    return _transactionLock.synchronized(() async {
      if (!mounted) return;

      setState(() => isLoading = true);

      try {
        await gSheetService.initialize();

        bool allInserted = true;
        final List<Map<String, dynamic>> productsToProcess = List.from(
          selectedProduct!,
        );

        for (final product in productsToProcess) {
          final int sellQty = product[kSellQuantity];

          log("Sale Quantity : $sellQty");
          if (sellQty == 0) {
            continue;
          }

          final currentStock = _parseIntValue(product[kProductQuantity]);
          if (sellQty > currentStock) {
            _showErrorSnackBar(
              '${'Insufficient stock for'.tr()} ${product[kProductName]}',
            );
            allInserted = false;
            break;
          }

          // Build employee username string: "UserType Username"
          final String? cachedUserType = CacheHelper.getData(kUserType);
          final String? cachedUsername = CacheHelper.getData(kUsername);
          final String userLabel = cachedUserType == kUserTypeManager
              ? 'Manager'
              : 'Employee';
          final String employeeUsername =
              '$userLabel ${cachedUsername ?? 'Unknown'}';

          final saleData = {
            kSaleId: const Uuid().v4(),
            kSaleProductId: product[kProductId],
            kSaleProductName: product[kProductName],
            kSaleProductPrice: product[kProductPrice].toString(),
            kSaleQuantity: sellQty.toString(),
            kEmployeeUsernameHeader: employeeUsername,
            kSaleCreatedDate: DateTime.now().toIso8601String(),
          };

          await gSheetService.addSale(saleData);

          final updatedProduct = {
            kProductId: product[kProductId],
            kProductBarcode: product[kProductBarcode],
            kProductName: product[kProductName],
            kProductPrice: product[kProductPrice],
            kProductQuantity: (currentStock - sellQty).toString(),
          };

          final updateSuccess = await gSheetService.updateProduct(
            product[kProductId],
            updatedProduct,
          );

          if (!updateSuccess) {
            allInserted = false;
            _showErrorSnackBar(
              '${'Failed to update stock for'.tr()} ${product[kProductName]}',
            );
            break;
          }
        }

        if (allInserted) {
          _showSuccessSnackBar('All products added successfully'.tr());
          await _productListLock.synchronized(() async {
            if (mounted) {
              setState(() => selectedProduct = null);

              // If manager, go back to dashboard
              final String? userType = CacheHelper.getData(kUserType);
              if (userType == kUserTypeManager) {
                Navigator.of(context).pushReplacementNamed(ManagerScreen.id);
              }
            }
          });
        } else {
          _showErrorSnackBar('Some products failed to add'.tr());
        }
      } catch (e) {
        log('Add products error: $e');
        _showErrorSnackBar('Error occurred: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    });
  }

  Future<void> _updateQuantity(Map<String, dynamic> product, int delta) async {
    await _productListLock.synchronized(() async {
      if (!mounted) return;

      final currentQty = _parseIntValue(product[kSellQuantity]);
      final stock = _parseIntValue(product[kProductQuantity]);
      final newQty = currentQty + delta;

      if (newQty < 0 || newQty > stock) {
        if (newQty > stock) {
          _showErrorSnackBar('Cannot exceed available stock'.tr());
        }
        return;
      }

      setState(() {
        product[kSellQuantity] = newQty;
      });
    });
  }

  // =========================
  // UI Helpers
  // =========================

  void _showSuccessSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // Helper method to parse int values from dynamic types
  int _parseIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // =========================
  // UI Widgets
  // =========================
  AppBar _buildAppBar() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text('Add Transaction'.tr()),
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onBackground,
      actions: [
        IconButton(
          onPressed: () {
            Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
          },
          icon: Icon(
            Provider.of<ThemeProvider>(context, listen: true).isDark
                ? Icons.mode_night_outlined
                : Icons.sunny,
            color: colorScheme.primary,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EmployeeAttendance()),
            );
          },
          icon: Icon(Icons.person, color: colorScheme.primary),
        ),
        IconButton(
          icon: Icon(Icons.logout, color: colorScheme.primary),
          tooltip: 'Logout',
          onPressed: isLoading
              ? null
              : () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Logout'.tr()),
                      content: Text('Are you sure you want to logout?'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'.tr()),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                          ),
                          child: Text('Logout'.tr()),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true && mounted) {
                    final authService = FirestoreAuthService();
                    await authService.logout();

                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(LoginSelectionScreen.id);
                    }
                  }
                },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _searchItems,
                icon: const Icon(Icons.search),
                label: Text('Find Product'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPreview() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    if (selectedProduct == null || selectedProduct!.isEmpty) {
      return Center(child: Text('No product selected'.tr()));
    }

    return Expanded(
      child: ListView.builder(
        itemCount: selectedProduct!.length,
        itemBuilder: (context, index) {
          final product = selectedProduct![index];
          final int stock = _parseIntValue(product[kProductQuantity]);
          final int sellQuantity = _parseIntValue(product[kSellQuantity]);
          final imageUrl = product[kProductImageUrl]?.toString();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: ProductImageWidget(
                imageUrl: imageUrl,
                size: 50,
                fallbackIcon: Icons.inventory_2,
              ),
              title: Text(
                product[kProductName] ?? 'Unknown Product',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                'Price: ${product[kProductPrice] ?? '-'}\n'
                'Stock: ${stock - sellQuantity}\n'
                'Quantity: $sellQuantity',
              ),
              trailing: SizedBox(
                width: 96,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: isLoading
                          ? null
                          : () => _updateQuantity(product, 1),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isLoading
                              ? Colors.grey.shade400
                              : Colors.grey.shade300,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                        ),
                        child: Icon(Icons.add, color: colorScheme.primary),
                      ),
                    ),
                    InkWell(
                      onTap: isLoading
                          ? null
                          : () => _updateQuantity(product, -1),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isLoading
                              ? Colors.grey.shade400
                              : Colors.grey.shade300,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: Icon(Icons.remove, color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddButton() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _addTransaction,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
        label: Text(isLoading ? 'Processing...'.tr() : 'Add Transaction'.tr()),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          disabledBackgroundColor: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildActionButtons(),
            const SizedBox(height: 16),
            _buildProductPreview(),
            const SizedBox(height: 16),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }
}
