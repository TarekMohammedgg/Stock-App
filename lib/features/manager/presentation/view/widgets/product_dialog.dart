import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/barcode_screen.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/text_input_number_formater.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';
import 'package:uuid/uuid.dart';

/// Unified Product Dialog for adding/editing products
/// Used by both ManagerScreen and SearchItemsScreen
class ProductDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onSave;

  const ProductDialog({this.product, required this.onSave});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final GSheetService gSheetService = GSheetService();

  late TextEditingController barcodeController;
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController buyPriceController;
  late TextEditingController quantityController;

  bool isUploading = false;
  bool isEditMode = false;
  bool hasExpiryDate = false;
  DateTime? expiryDate;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.product != null;

    barcodeController = TextEditingController(
      text: widget.product?[kProductBarcode]?.toString() ?? '',
    );
    nameController = TextEditingController(
      text: widget.product?[kProductName]?.toString() ?? '',
    );
    priceController = TextEditingController(
      text: widget.product?[kProductPrice]?.toString() ?? '',
    );
    buyPriceController = TextEditingController();
    quantityController = TextEditingController();
  }

  @override
  void dispose() {
    barcodeController.dispose();
    nameController.dispose();
    priceController.dispose();
    buyPriceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (result != null) {
      setState(() {
        barcodeController.text = result;
      });
    }
  }

  void _generateBarcode() {
    setState(() {
      barcodeController.text = const Uuid().v4();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Barcode generated'.tr()),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Select Expiry Date'.tr(),
    );
    if (picked != null) {
      setState(() {
        expiryDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate expiry date if checkbox is checked
    if (hasExpiryDate && expiryDate == null) {
      _showErrorSnackBar('Please select an expiry date'.tr());
      return;
    }

    setState(() => isUploading = true);

    try {
      await gSheetService.initialize();

      // Generate UUID if barcode is empty
      final finalBarcode = barcodeController.text.trim().isEmpty
          ? const Uuid().v4()
          : barcodeController.text.trim();

      final productId = isEditMode
          ? widget.product![kProductId]?.toString() ?? const Uuid().v4()
          : const Uuid().v4();

      // Product data (basic info)
      final productData = {
        kProductId: productId,
        kProductBarcode: finalBarcode,
        kProductName: nameController.text.trim(),
        // Remove commas from formatted price before saving
        kProductPrice: priceController.text.trim().replaceAll(',', ''),
      };

      bool success;
      if (isEditMode) {
        success = await gSheetService.updateProduct(
          widget.product![kProductId]?.toString() ?? '',
          productData,
        );
      } else {
        success = await gSheetService.addProduct(productData);

        // For new products, also create a ProductItem (batch) if quantity is provided
        if (success) {
          final quantityText = quantityController.text.trim().replaceAll(
            ',',
            '',
          );
          final buyPriceText = buyPriceController.text.trim().replaceAll(
            ',',
            '',
          );

          if (quantityText.isNotEmpty && buyPriceText.isNotEmpty) {
            final quantity = int.tryParse(quantityText);
            final buyPrice = double.tryParse(buyPriceText);

            if (quantity != null && quantity > 0 && buyPrice != null) {
              final productItemData = {
                kProductItemId: const Uuid().v4(),
                kProductItemProductId: productId,
                kProductItemBuyPrice: buyPrice.toString(),
                kProductItemQuantity: quantity.toString(),
                kProductItemCreatedAt: DateTime.now().toIso8601String(),
                kProductItemExpiredAt: hasExpiryDate && expiryDate != null
                    ? expiryDate!.toIso8601String()
                    : '',
              };
              await gSheetService.addProductItem(productItemData);
            }
          }
        }
      }

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSave();
        }
      } else {
        _showErrorSnackBar('Failed to save product'.tr());
      }
    } catch (e) {
      log('Submit error: $e');
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => isUploading = false);
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Get screen size for responsive dialog
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        isEditMode ? Icons.edit : Icons.add_box,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEditMode
                              ? 'Edit Product'.tr()
                              : 'Add New Product'.tr(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Barcode field with scanner and auto-generate buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: barcodeController,
                          decoration: InputDecoration(
                            labelText: 'Barcode'.tr(),
                            hintText: 'Scan or enter barcode'.tr(),
                            prefixIcon: const Icon(Icons.qr_code),
                            border: const OutlineInputBorder(),
                            helperText: 'Leave empty to auto-generate'.tr(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          IconButton.filled(
                            onPressed: _scanBarcode,
                            icon: const Icon(Icons.qr_code_scanner),
                            tooltip: 'Scan Barcode'.tr(),
                          ),
                          const SizedBox(height: 4),
                          IconButton.outlined(
                            onPressed: _generateBarcode,
                            icon: const Icon(Icons.auto_awesome),
                            tooltip: 'Auto Generate'.tr(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Product Name
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name'.tr(),
                      prefixIcon: const Icon(Icons.shopping_bag),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required'.tr() : null,
                  ),
                  const SizedBox(height: 16),

                  // Selling Price with NumberTextInputFormatter
                  TextFormField(
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      NumberTextInputFormatter(),
                    ],
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Selling Price'.tr(),
                      prefixIcon: const Icon(Icons.attach_money),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required'.tr();
                      final cleanValue = v.replaceAll(',', '');
                      if (double.tryParse(cleanValue) == null) {
                        return 'Invalid number'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Only show Buy Price and Quantity for new products
                  if (!isEditMode) ...[
                    // Buy Price (Cost) with NumberTextInputFormatter
                    TextFormField(
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        NumberTextInputFormatter(),
                      ],
                      controller: buyPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Buy Price (Cost)'.tr(),
                        prefixIcon: const Icon(Icons.money_off),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required'.tr();
                        final cleanValue = v.replaceAll(',', '');
                        if (double.tryParse(cleanValue) == null) {
                          return 'Invalid number'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Initial Quantity with NumberTextInputFormatter
                    TextFormField(
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        NumberTextInputFormatter(),
                      ],
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Initial Quantity'.tr(),
                        prefixIcon: const Icon(Icons.inventory),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required'.tr();
                        final cleanValue = v.replaceAll(',', '');
                        if (int.tryParse(cleanValue) == null) {
                          return 'Invalid number'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Expiry Date Section
                    Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Expiry Date Checkbox
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Has Expiry Date'.tr(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                'Enable if this product has an expiration date'
                                    .tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              value: hasExpiryDate,
                              onChanged: (value) {
                                setState(() {
                                  hasExpiryDate = value ?? false;
                                  if (!hasExpiryDate) {
                                    expiryDate = null;
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),

                            // Expiry Date Picker
                            if (hasExpiryDate) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _selectExpiryDate,
                                icon: Icon(
                                  expiryDate != null
                                      ? Icons.event_available
                                      : Icons.event,
                                  color: expiryDate != null
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withOpacity(0.6),
                                ),
                                label: Text(
                                  expiryDate != null
                                      ? '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
                                      : 'Select Expiry Date'.tr(),
                                  style: TextStyle(
                                    color: expiryDate != null
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                  side: BorderSide(
                                    color: expiryDate != null
                                        ? colorScheme.primary
                                        : colorScheme.outline,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: isUploading ? null : _submit,
                    icon: isUploading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Icon(isEditMode ? Icons.save : Icons.add),
                    label: Text(
                      isUploading
                          ? 'Saving...'.tr()
                          : isEditMode
                          ? 'Update Product'.tr()
                          : 'Add Product'.tr(),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
