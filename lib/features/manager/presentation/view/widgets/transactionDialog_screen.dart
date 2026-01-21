import 'dart:developer';

import 'package:flutter/material.dart';
// import 'package:gdrive_tutorial/core/app_theme.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';
import 'package:uuid/uuid.dart';

class TransactionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final VoidCallback onSave;

  const TransactionDialog({
    super.key,
    required this.products,
    required this.onSave,
  });

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final GSheetService gSheetService = GSheetService();

  Map<String, dynamic>? selectedProduct;
  final TextEditingController quantityController = TextEditingController();
  bool isSaving = false;

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || selectedProduct == null) return;

    final int sellQty = int.tryParse(quantityController.text) ?? 0;
    if (sellQty <= 0) {
      _showErrorSnackBar('Quantity must be greater than 0');
      return;
    }

    final currentStock =
        int.tryParse(selectedProduct![kProductQuantity].toString()) ?? 0;
    if (sellQty > currentStock) {
      _showErrorSnackBar('Insufficient stock');
      return;
    }

    setState(() => isSaving = true);

    try {
      await gSheetService.initialize();

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
        kSaleProductId: selectedProduct![kProductId],
        kSaleProductName: selectedProduct![kProductName],
        kSaleProductPrice: selectedProduct![kProductPrice].toString(),
        kSaleQuantity: sellQty.toString(),
        kEmployeeUsernameHeader: employeeUsername,
        kSaleCreatedDate: DateTime.now().toIso8601String(),
      };

      // Add sale record
      await gSheetService.addSale(saleData);

      // Update product stock
      final updatedProduct = {
        kProductId: selectedProduct![kProductId],
        kProductBarcode: selectedProduct![kProductBarcode],
        kProductName: selectedProduct![kProductName],
        kProductPrice: selectedProduct![kProductPrice],
        kProductQuantity: (currentStock - sellQty).toString(),
      };

      final updateSuccess = await gSheetService.updateProduct(
        selectedProduct![kProductId].toString(),
        updatedProduct,
      );

      if (updateSuccess) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction recorded!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorSnackBar('Failed to update stock');
      }
    } catch (e) {
      log('Transaction error: $e');
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Record Sale',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<Map<String, dynamic>>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Select Product',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_basket),
                ),
                items: widget.products
                    .where((p) {
                      // Only show products with stock
                      final stock =
                          int.tryParse(p[kProductQuantity].toString()) ?? 0;
                      return stock > 0;
                    })
                    .map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(
                          '${p[kProductName]} (\$${p[kProductPrice]}) [${p[kProductQuantity]} left]',
                        ),
                      );
                    })
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedProduct = value);
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity to Sell',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_shopping_cart),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isSaving ? null : _submit,
                icon: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(isSaving ? 'Processing...' : 'Record Sale'),
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
    );
  }
}
