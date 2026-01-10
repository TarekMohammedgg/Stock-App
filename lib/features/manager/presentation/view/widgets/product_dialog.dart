import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/barcode_screen.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/text_input_number_formater.dart';
import 'package:gdrive_tutorial/services/gdrive_service.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';
import 'package:uuid/uuid.dart';

class ProductDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onSave;

  const ProductDialog({this.product, required this.onSave});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final GDriveService gDriveService = GDriveService();
  final GSheetService gSheetService = GSheetService();

  late TextEditingController barcodeController;
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController quantityController;

  // File? selectedFile;
  bool isUploading = false;
  bool isEditMode = false;
  String? scannedBarcode;

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
    quantityController = TextEditingController(
      text: widget.product?[kProductQuantity]?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    barcodeController.dispose();
    nameController.dispose();
    priceController.dispose();
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
        scannedBarcode = result;
        barcodeController.text = result;
      });
    }
  }

  // Future<void> _pickFile() async {
  //   final result = await FilePicker.platform.pickFiles(
  //     allowMultiple: false,
  //     type: FileType.image,
  //   );
  //
  //   if (result == null || result.files.single.path == null) return;
  //
  //   setState(() {
  //     selectedFile = File(result.files.single.path!);
  //   });
  // }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isUploading = true);

    try {
      await gSheetService.initialize();

      // ===== IMAGE UPLOAD DISABLED =====
      // String? imageUrl;
      //
      // // Upload file if selected and get the URL
      // if (selectedFile != null) {
      //   imageUrl = await gDriveService.uploadProductImage(selectedFile!);
      //
      //   if (imageUrl == null) {
      //     _showErrorSnackBar('Failed to upload image');
      //     setState(() => isUploading = false);
      //     return;
      //   }
      //   log("Image url is : $imageUrl");
      // }
      // ===== IMAGE UPLOAD DISABLED =====

      // Generate UUID if barcode is empty
      final finalBarcode = barcodeController.text.trim().isEmpty
          ? const Uuid().v4()
          : barcodeController.text.trim();

      final productData = {
        kProductId: isEditMode
            ? widget.product![kProductId]
            : const Uuid().v4(),
        kProductBarcode: finalBarcode,
        kProductName: nameController.text.trim(),
        // Remove commas from formatted price before saving
        kProductPrice: priceController.text.trim().replaceAll(',', ''),
        kProductQuantity: quantityController.text.trim().replaceAll(',', ''),
        // kProductImageUrl: imageUrl ?? '', // Image upload disabled
      };

      bool success;
      if (isEditMode) {
        success = await gSheetService.updateProduct(
          widget.product![kProductId]?.toString() ?? '',
          productData,
        );
      } else {
        success = await gSheetService.addProduct(productData);
      }

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSave();
        }
      } else {
        _showErrorSnackBar('Failed to save product');
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
                  Row(
                    children: [
                      Icon(isEditMode ? Icons.edit : Icons.add_box),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEditMode ? 'Edit Product' : 'Add New Product',
                          style: const TextStyle(
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
                  const SizedBox(height: 24),

                  // Barcode field with scanner
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Barcode (Optional)',
                            hintText: 'Scan or enter barcode',
                            prefixIcon: Icon(Icons.qr_code),
                            border: OutlineInputBorder(),
                            helperText: 'Leave empty to auto-generate',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner),
                        tooltip: 'Scan Barcode',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      prefixIcon: Icon(Icons.shopping_bag),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      NumberTextInputFormatter(),
                    ],
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      // Remove commas before parsing (formatter adds them)
                      final cleanValue = v.replaceAll(',', '');
                      if (double.tryParse(cleanValue) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.inventory),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (int.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Image upload
                  /*
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.image),
                    label: Text(
                      selectedFile == null
                          ? 'Add Image (Optional)'
                          : 'Image Selected',
                    ),
                  ),

                  if (selectedFile != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(selectedFile!, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                  */
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: isUploading ? null : _submit,
                    icon: isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isEditMode ? Icons.save : Icons.add),
                    label: Text(
                      isUploading
                          ? 'Saving...'
                          : isEditMode
                          ? 'Update Product'
                          : 'Add Product',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
