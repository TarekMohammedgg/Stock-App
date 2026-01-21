import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/permission_helper.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/product_dialog.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';

class SearchItemsScreen extends StatefulWidget {
  static const String id = 'search_items_screen';
  const SearchItemsScreen({super.key});

  @override
  State<SearchItemsScreen> createState() => _SearchItemsScreenState();
}

class _SearchItemsScreenState extends State<SearchItemsScreen> {
  final GSheetService gSheetService = GSheetService();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> allProducts = []; // Products basic info
  List<Map<String, dynamic>> allProductItems = []; // Product items (batches)
  List<Map<String, dynamic>> displayItems = []; // Combined for display
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// WHY THIS ERROR HAPPENS:
  /// When you navigate away from this screen while an async operation (like
  /// fetching products from Google Sheets) is in progress, the operation
  /// completes AFTER the widget is removed from the widget tree.
  /// When setState() is then called, Flutter throws this error because
  /// the State object no longer exists.
  ///
  /// SOLUTION: Always check 'mounted' before calling setState() after
  /// any async operation (await, Future.then, Timer, Animation callbacks).

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await gSheetService.initialize();

      // Load both Products and ProductItems
      final products = await gSheetService.getProducts();
      final productItems = await gSheetService.getProductItems();

      log("products: $products");
      log("productItems: $productItems");

      if (!mounted) return;

      // Create display items by joining ProductItems with Product info
      final List<Map<String, dynamic>> combined = [];
      for (var item in productItems) {
        final productId = item[kProductItemProductId]?.toString();
        final product = products.firstWhere(
          (p) => p[kProductId]?.toString() == productId,
          orElse: () => <String, dynamic>{},
        );

        if (product.isNotEmpty) {
          combined.add({
            ...item,
            kProductName: product[kProductName],
            kProductPrice: product[kProductPrice],
            kProductBarcode: product[kProductBarcode],
          });
        }
      }

      setState(() {
        allProducts = products;
        allProductItems = productItems;
        displayItems = combined;
        isLoading = false;
      });
    } catch (e) {
      log('Error loading products: $e');

      if (!mounted) return;

      setState(() {
        errorMessage = 'Failed to load products: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    try {
      final products = await gSheetService.getProducts();
      final productItems = await gSheetService.getProductItems();

      if (!mounted) return;

      // Create display items by joining ProductItems with Product info
      final List<Map<String, dynamic>> combined = [];
      for (var item in productItems) {
        final productId = item[kProductItemProductId]?.toString();
        final product = products.firstWhere(
          (p) => p[kProductId]?.toString() == productId,
          orElse: () => <String, dynamic>{},
        );

        if (product.isNotEmpty) {
          combined.add({
            ...item,
            kProductName: product[kProductName],
            kProductPrice: product[kProductPrice],
            kProductBarcode: product[kProductBarcode],
          });
        }
      }

      setState(() {
        allProducts = products;
        allProductItems = productItems;
        displayItems = combined;
      });
    } catch (e) {
      log('Error loading products: $e');

      if (!mounted) return;

      setState(() {
        errorMessage = 'Failed to load products: $e';
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        // Show all items when no search
        final List<Map<String, dynamic>> combined = [];
        for (var item in allProductItems) {
          final productId = item[kProductItemProductId]?.toString();
          final product = allProducts.firstWhere(
            (p) => p[kProductId]?.toString() == productId,
            orElse: () => <String, dynamic>{},
          );

          if (product.isNotEmpty) {
            combined.add({
              ...item,
              kProductName: product[kProductName],
              kProductPrice: product[kProductPrice],
              kProductBarcode: product[kProductBarcode],
            });
          }
        }
        displayItems = combined;
      } else {
        // Filter by product name OR barcode
        final searchLower = query.toLowerCase();

        // First rebuild all combined items then filter
        final List<Map<String, dynamic>> combined = [];
        for (var item in allProductItems) {
          final productId = item[kProductItemProductId]?.toString();
          final product = allProducts.firstWhere(
            (p) => p[kProductId]?.toString() == productId,
            orElse: () => <String, dynamic>{},
          );

          if (product.isNotEmpty) {
            combined.add({
              ...item,
              kProductName: product[kProductName],
              kProductPrice: product[kProductPrice],
              kProductBarcode: product[kProductBarcode],
            });
          }
        }

        displayItems = combined.where((item) {
          final productName =
              item[kProductName]?.toString().toLowerCase() ?? '';
          final productBarcode =
              item[kProductBarcode]?.toString().toLowerCase() ?? '';
          return productName.contains(searchLower) ||
              productBarcode.contains(searchLower);
        }).toList();
      }
    });
  }

  /// Scan barcode and search for matching product
  Future<void> _scanBarcode() async {
    final scannedBarcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _BarcodeScannerView()),
    );

    if (scannedBarcode != null && scannedBarcode.isNotEmpty && mounted) {
      // Search for product with matching barcode
      final matchingProduct = displayItems.firstWhere(
        (item) =>
            item[kProductBarcode]?.toString().toLowerCase() ==
            scannedBarcode.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      if (matchingProduct.isNotEmpty) {
        // Check if product is in stock
        final stock = _parseInt(matchingProduct[kProductItemQuantity]) ?? 0;
        if (stock > 0) {
          _selectProduct(matchingProduct);
        } else {
          _showErrorSnackBar('Product is out of stock'.tr());
        }
      } else {
        // Show message and set search text to scanned barcode
        searchController.text = scannedBarcode;
        _filterProducts(scannedBarcode);
        _showErrorSnackBar('No product found with this barcode'.tr());
      }
    }
  }

  void _selectProduct(Map<String, dynamic> productItem) {
    // Return the selected product item data with proper type conversion
    final result = {
      kProductItemId: productItem[kProductItemId]?.toString() ?? '',
      kProductId: productItem[kProductItemProductId]?.toString() ?? '',
      kProductBarcode: productItem[kProductBarcode]?.toString() ?? '',
      kProductName: productItem[kProductName]?.toString() ?? '',
      kProductPrice: _parseDouble(productItem[kProductPrice]) ?? 0.0,
      kProductItemQuantity: _parseInt(productItem[kProductItemQuantity]) ?? 0,
      kProductItemBuyPrice:
          _parseDouble(productItem[kProductItemBuyPrice]) ?? 0.0,
    };

    Navigator.pop(context, result);
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  void _showAddProductDialog() async {
    // Check permission first
    final hasPermission = await PermissionHelper.canAddProduct();
    if (!hasPermission) {
      _showErrorSnackBar('You do not have permission to add products'.tr());
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ProductDialog(onSave: () => _loadProducts()),
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text('Search Items'.tr()),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onBackground,
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: colorScheme.primary),
            tooltip: 'Scan Barcode'.tr(),
            onPressed: _scanBarcode,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: _loadProducts,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Search by name or barcode'.tr(),
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          _filterProducts('');
                        },
                        icon: Icon(Icons.clear, color: colorScheme.primary),
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterProducts,
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
      body: StreamBuilder(
        stream: Stream.periodic(
          Duration(seconds: 5),
        ).asyncMap((i) => _fetchData()),
        builder: (context, snapshot) {
          return _buildBody();
        },
      ),
    );
  }

  Widget _buildBody() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Error'.tr(), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProducts,
                icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
                label: Text('Retry'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (displayItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                searchController.text.isEmpty
                    ? Icons.inventory_2_outlined
                    : Icons.search_off,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                searchController.text.isEmpty
                    ? 'No Products Found'.tr()
                    : 'No Results'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                searchController.text.isEmpty
                    ? 'Add some products to get started'.tr()
                    : 'Try a different search term'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final productItem = displayItems[index];
        return productItem[kProductItemId] != null &&
                productItem[kProductItemId].toString().isNotEmpty &&
                productItem[kProductName] != null &&
                productItem[kProductName].toString().isNotEmpty
            ? _buildProductCard(context, productItem)
            : const SizedBox.shrink();
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Map<String, dynamic> productItem,
  ) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    final productName = productItem[kProductName] ?? 'Unknown';
    final price = productItem[kProductPrice] ?? '0';
    final stockQuantity = productItem[kProductItemQuantity] ?? '0';

    // Determine stock status
    final stock = _parseInt(stockQuantity) ?? 0;
    Color stockColor;
    String stockStatus;
    if (stock <= 0) {
      stockColor = Colors.red;
      stockStatus = 'Out of Stock'.tr();
    } else {
      stockColor = Colors.green;
      stockStatus = 'In Stock'.tr();
    }

    return Card(
      color: stock <= 0 ? Colors.red.shade100 : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: stock <= 0 ? () {} : () => _selectProduct(productItem),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Icon (no image in ProductItems)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stockStatus,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: stockColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.green),
                        Text(
                          price.toString(),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.inventory, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          stockQuantity.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Select Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Private Barcode Scanner View for this screen
class _BarcodeScannerView extends StatefulWidget {
  const _BarcodeScannerView();

  @override
  State<_BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<_BarcodeScannerView> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Barcode'.tr()),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onBackground,
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on, color: colorScheme.primary),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: Icon(Icons.flip_camera_ios, color: colorScheme.primary),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (isScanned) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first.rawValue;
                if (barcode != null) {
                  setState(() => isScanned = true);
                  Navigator.pop(context, barcode);
                }
              }
            },
          ),
          // Overlay with scan area indicator
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Point camera at barcode'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
