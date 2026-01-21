import 'dart:async';
import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:gdrive_tutorial/core/consts.dart';

import 'package:gdrive_tutorial/core/theme/toggle_theme.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/login_selection_screen.dart';
import 'package:gdrive_tutorial/services/firestore_auth_service.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/manager_screen.dart';
import 'package:gdrive_tutorial/features/search_products/presentation/view/search_items_screen.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:synchronized/synchronized.dart';

/// Manager Transaction Screen - Similar to Employee Screen but without attendance check-in icon
/// Managers don't need to check in before making transactions
class ManagerTransactionScreen extends StatefulWidget {
  static const String id = 'manager_transaction_screen';
  const ManagerTransactionScreen({super.key});

  @override
  State<ManagerTransactionScreen> createState() =>
      _ManagerTransactionScreenState();
}

class _ManagerTransactionScreenState extends State<ManagerTransactionScreen> {
  final GSheetService gSheetService = GSheetService();

  // Locks for synchronized operations
  final Lock _transactionLock = Lock();
  final Lock _productListLock = Lock();

  MobileScannerController? scannerController;

  // Note controller for transaction notes
  final TextEditingController _noteController = TextEditingController();

  bool isLoading = false;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
  }

  /// Product loaded from scan or search
  List<Map<String, dynamic>>? selectedProduct;

  @override
  void dispose() {
    scannerController?.dispose();
    _noteController.dispose();
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
          // Check by ProductItemId for new workflow
          final exists = selectedProduct!.any(
            (p) => p[kProductItemId] == result[kProductItemId],
          );
          if (exists) {
            _showErrorSnackBar('Product already added'.tr());
            return;
          }
          result[kSellQuantity] = 0;
          selectedProduct!.add(result);
        });
      });

      _showSuccessSnackBar('${'Item loaded'.tr()}: ${result[kProductName]}');
    }
  }

  /// Calculate total price of all products in cart
  double _calculateTotalPrice() {
    if (selectedProduct == null || selectedProduct!.isEmpty) return 0;
    double total = 0;
    for (final product in selectedProduct!) {
      final price = _parseDoubleValue(product[kProductPrice]);
      final qty = _parseIntValue(product[kSellQuantity]);
      total += price * qty;
    }
    return total;
  }

  double _parseDoubleValue(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _addTransaction() async {
    // Manager doesn't need attendance check - direct transaction processing
    setState(() => isLoading = true);

    // Manager has full permission - skip permission check
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

        // Generate sequential Invoice Number for this transaction (001, 002, 003...)
        final saleId = await gSheetService.getNextInvoiceNumber();
        final totalPrice = _calculateTotalPrice();

        // Build manager username string
        final String? cachedUsername = CacheHelper.getData(kUsername);
        final String employeeUsername =
            'Manager ${cachedUsername ?? 'Unknown'}';

        // Step 1: Create Sale record (invoice header)
        final saleData = {
          kSalesId: saleId,
          kSalesTotalPrice: totalPrice.toString(),
          kSalesCreatedDate: DateTime.now().toIso8601String(),
          kSalesEmployeeUsername: employeeUsername,
          kSalesNote: _noteController.text.trim(),
        };
        await gSheetService.addSale(saleData);

        // Step 2: Create SalesItems and update ProductItem quantities
        bool allSuccess = true;
        final List<Map<String, dynamic>> productsToProcess = List.from(
          selectedProduct!,
        );

        for (final product in productsToProcess) {
          final int sellQty = _parseIntValue(product[kSellQuantity]);

          log("Sale Quantity : $sellQty");
          if (sellQty == 0) {
            continue;
          }

          // Check stock from ProductItem
          final currentStock = _parseIntValue(product[kProductItemQuantity]);
          if (sellQty > currentStock) {
            _showErrorSnackBar(
              '${'Insufficient stock for'.tr()} ${product[kProductName]}',
            );
            allSuccess = false;
            break;
          }

          // Add SalesItem record
          final salesItemData = {
            kSalesItemId: const Uuid().v4(),
            kSalesItemSalesId: saleId,
            kSalesItemProductId: product[kProductId],
            kSalesItemQuantity: sellQty.toString(),
            kSalesItemPrice: product[kProductPrice].toString(),
          };
          await gSheetService.addSalesItem(salesItemData);

          // Update ProductItem quantity
          final productItemId = product[kProductItemId];
          if (productItemId != null) {
            final updatedProductItem = {
              kProductItemId: productItemId,
              kProductItemProductId: product[kProductId],
              kProductItemBuyPrice:
                  product[kProductItemBuyPrice]?.toString() ?? '0',
              kProductItemQuantity: (currentStock - sellQty).toString(),
              kProductItemCreatedAt:
                  product[kProductItemCreatedAt]?.toString() ?? '',
              kProductItemExpiredAt:
                  product[kProductItemExpiredAt]?.toString() ?? '',
            };

            final updateSuccess = await gSheetService.updateProductItem(
              productItemId,
              updatedProductItem,
            );

            if (!updateSuccess) {
              allSuccess = false;
              _showErrorSnackBar(
                '${'Failed to update stock for'.tr()} ${product[kProductName]}',
              );
              break;
            }
          }
        }

        if (allSuccess) {
          _showSuccessSnackBar('Transaction completed successfully'.tr());
          await _productListLock.synchronized(() async {
            if (mounted) {
              setState(() {
                selectedProduct = null;
                _noteController.clear();
              });
              // Navigate back to manager dashboard
              Navigator.of(context).pushReplacementNamed(ManagerScreen.id);
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
      final stock = _parseIntValue(
        product[kProductItemQuantity],
      ); // Use ProductItem quantity
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
      title: Text('Add Transaction'.tr()),
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      actions: [
        // Theme toggle button
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
        // Note: No person/attendance icon for manager - managers don't need to check in
        // Logout button
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
          final int stock = _parseIntValue(
            product[kProductItemQuantity],
          ); // Use ProductItem quantity
          final int sellQuantity = _parseIntValue(product[kSellQuantity]);
          final double price = _parseDoubleValue(product[kProductPrice]);
          final double subtotal = price * sellQuantity;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2, color: colorScheme.primary),
              ),
              title: Text(
                product[kProductName] ?? 'Unknown Product',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price: \$${price.toStringAsFixed(2)}'),
                  Text('Stock: ${stock - sellQuantity} | Qty: $sellQuantity'),
                  Text(
                    'Subtotal: \$${subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: subtotal > 0
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              trailing: SizedBox(
                width: 96,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          borderRadius: const BorderRadiusDirectional.only(
                            topStart: Radius.circular(6),
                            bottomStart: Radius.circular(6),
                          ),
                        ),
                        child: Icon(Icons.remove, color: colorScheme.primary),
                      ),
                    ),
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
                          borderRadius: const BorderRadiusDirectional.only(
                            topEnd: Radius.circular(6),
                            bottomEnd: Radius.circular(6),
                          ),
                        ),
                        child: Icon(Icons.add, color: colorScheme.primary),
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

  /// Build total price display widget - Always visible
  Widget _buildTotalPrice() {
    final total = _calculateTotalPrice();
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Always show Total
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: total > 0 ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: total > 0
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _noteController,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: 'Note (Optional)'.tr(),
          hintText: 'Add a note for this transaction...'.tr(),
          prefixIcon: Icon(Icons.note_alt_outlined, color: colorScheme.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: colorScheme.surface,
        ),
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
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildActionButtons(),
            const SizedBox(height: 16),
            _buildProductPreview(),
            const SizedBox(height: 8),
            _buildTotalPrice(),
            _buildNoteInput(),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }
}
