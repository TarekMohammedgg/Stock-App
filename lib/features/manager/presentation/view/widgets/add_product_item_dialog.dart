import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/features/manager/data/models/product_item.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/text_input_number_formater.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';
import 'package:uuid/uuid.dart';

/// Dialog for adding a new product batch/lot
/// This creates a ProductItem record linked to an existing Product
class AddProductItemDialog extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final VoidCallback onSave;
  final String? preselectedProductId;

  const AddProductItemDialog({
    super.key,
    required this.products,
    required this.onSave,
    this.preselectedProductId,
  });

  @override
  State<AddProductItemDialog> createState() => _AddProductItemDialogState();
}

class _AddProductItemDialogState extends State<AddProductItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final GSheetService gSheetService = GSheetService();

  Map<String, dynamic>? selectedProduct;
  final TextEditingController buyPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  DateTime? expiryDate;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-select product if provided
    if (widget.preselectedProductId != null) {
      selectedProduct = widget.products.firstWhere(
        (p) => p[kProductId] == widget.preselectedProductId,
        orElse: () => <String, dynamic>{},
      );
      if (selectedProduct!.isEmpty) selectedProduct = null;
    }
  }

  @override
  void dispose() {
    buyPriceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Select Expiry Date (Optional)',
    );
    if (picked != null) {
      setState(() {
        expiryDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || selectedProduct == null) {
      _showErrorSnackBar(
        'Please select a product and fill all required fields',
      );
      return;
    }

    final int qty =
        int.tryParse(quantityController.text.replaceAll(',', '')) ?? 0;
    if (qty <= 0) {
      _showErrorSnackBar('Quantity must be greater than 0');
      return;
    }

    setState(() => isSaving = true);

    try {
      await gSheetService.initialize();

      final productItem = ProductItem(
        id: const Uuid().v4(),
        productId: selectedProduct![kProductId]?.toString() ?? '',
        buyPrice:
            double.tryParse(buyPriceController.text.replaceAll(',', '')) ?? 0.0,
        quantity: qty,
        createdAt: DateTime.now(),
        expiredAt: expiryDate,
      );

      final result = await gSheetService.addProductItem(productItem.toMap());

      if (result) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Added $qty units of ${selectedProduct![kProductName]}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorSnackBar('Failed to add product batch');
      }
    } catch (e) {
      log('Add product item error: $e');
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
    final colorScheme = Theme.of(context).colorScheme;

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
                      Icon(Icons.inventory_2, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Add Product Batch',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add inventory for an existing product',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Product Selection
                  DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    value: selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Select Product',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag),
                    ),
                    items: widget.products.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(
                          '${p[kProductName]} - \$${p[kProductPrice]}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedProduct = value);
                    },
                    validator: (v) =>
                        v == null ? 'Please select a product' : null,
                  ),
                  const SizedBox(height: 16),

                  // Buy Price
                  TextFormField(
                    controller: buyPriceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      NumberTextInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Buy Price (Cost)',
                      hintText: 'Enter purchase price',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      helperText: 'Price you paid for this batch',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final cleanValue = v.replaceAll(',', '');
                      if (double.tryParse(cleanValue) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quantity
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      NumberTextInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      hintText: 'Enter quantity',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final cleanValue = v.replaceAll(',', '');
                      if (int.tryParse(cleanValue) == null)
                        return 'Invalid number';
                      if (int.parse(cleanValue) <= 0)
                        return 'Must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Expiry Date (Optional)
                  OutlinedButton.icon(
                    onPressed: _selectExpiryDate,
                    icon: Icon(
                      expiryDate != null ? Icons.event_available : Icons.event,
                    ),
                    label: Text(
                      expiryDate != null
                          ? 'Expires: ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
                          : 'Set Expiry Date (Optional)',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  if (expiryDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: () => setState(() => expiryDate = null),
                        child: const Text('Clear Expiry Date'),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: isSaving ? null : _submit,
                    icon: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(isSaving ? 'Adding...' : 'Add Batch'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
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
