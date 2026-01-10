import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/permission_helper.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';
import 'package:gdrive_tutorial/core/widgets/product_image_widget.dart';
import 'package:uuid/uuid.dart';

class SearchItemsScreen extends StatefulWidget {
  static const String id = 'search_items_screen';
  const SearchItemsScreen({super.key});

  @override
  State<SearchItemsScreen> createState() => _SearchItemsScreenState();
}

class _SearchItemsScreenState extends State<SearchItemsScreen> {
  final GSheetService gSheetService = GSheetService();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
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
    if (!mounted) return; // Guard: Exit if widget was disposed

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Initialize and get products from Google Sheets
      await gSheetService.initialize();
      final products = await gSheetService.getProducts();
      log("products: $products");

      // Guard: Check mounted again after async operation
      if (!mounted) return;

      setState(() {
        allProducts = products ?? [];
        filteredProducts = allProducts;
        isLoading = false;
      });
    } catch (e) {
      log('Error loading products: $e');

      // Guard: Check mounted before setState in error handler
      if (!mounted) return;

      setState(() {
        errorMessage = 'Failed to load products: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchData() async {
    // Guard: Exit early if widget is no longer mounted
    if (!mounted) return;

    try {
      // Fetch latest products data
      final products = await gSheetService.getProducts();
      log("products: $products");

      // Guard: Check mounted after async operation
      if (!mounted) return;

      setState(() {
        allProducts = products ?? [];
        filteredProducts = allProducts;
      });
    } catch (e) {
      log('Error loading products: $e');

      // Guard: Check mounted before setState
      if (!mounted) return;

      setState(() {
        errorMessage = 'Failed to load products: $e';
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = allProducts;
      } else {
        filteredProducts = allProducts.where((product) {
          final productName =
              product[kProductName]?.toString().toLowerCase() ?? '';

          final searchLower = query.toLowerCase();

          return productName.contains(searchLower);
        }).toList();
      }
    });
  }

  void _selectProduct(Map<String, dynamic> product) {
    // Return the selected product data with proper type conversion
    final result = {
      kProductId: product[kProductId]?.toString() ?? '',
      kProductBarcode: product[kProductBarcode]?.toString() ?? '',
      kProductName: product[kProductName]?.toString() ?? '',
      kProductPrice: _parseDouble(product[kProductPrice]) ?? 0.0,
      kProductQuantity: _parseInt(product[kProductQuantity]) ?? 0,
      kProductImageUrl:
          product[kProductImageUrl]?.toString() ?? '', // Include image URL
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
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isAdding = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            ColorScheme colorScheme = Theme.of(context).colorScheme;
            return AlertDialog(
              title: Text('Add Product'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Product Name'.tr()),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Price'.tr()),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Quantity'.tr()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel'.tr(),
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text);
                    final quantity = int.tryParse(quantityController.text);

                    if (name.isEmpty || price == null || quantity == null) {
                      return;
                    }

                    // ✅ Handle data here
                    try {
                      setDialogState(() {
                        isAdding = true;
                      });

                      final newProduct = {
                        kProductId: Uuid().v4(),
                        kProductBarcode: Uuid().v4(),
                        kProductName: name,
                        kProductPrice: price.toString(),
                        kProductQuantity: quantity.toString(),
                      };

                      await gSheetService.addProduct(newProduct);
                      _showSuccessSnackBar('Product added successfully'.tr());
                      _loadProducts();
                    } catch (e) {
                      log("error when upload new product ");
                    }
                    setDialogState(() {
                      isAdding = false;
                    });

                    Navigator.pop(dialogContext);
                  },
                  child: isAdding
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text('Add'.tr()),
                ),
              ],
            );
          },
        );
      },
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
                hintText: 'Search by name'.tr(),
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

    if (filteredProducts.isEmpty) {
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
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return product[kProductId] != null &&
                product[kProductId].toString().isNotEmpty &&
                product[kProductBarcode] != null &&
                product[kProductBarcode].toString().isNotEmpty &&
                product[kProductName] != null &&
                product[kProductName].toString().isNotEmpty &&
                product[kProductPrice] != null &&
                product[kProductPrice].toString().isNotEmpty &&
                product[kProductQuantity] != null &&
                product[kProductQuantity].toString().isNotEmpty
            ? _buildProductCard(context, product)
            : const SizedBox.shrink(); // or return nothing;
        // return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    final productName = product[kProductName] ?? 'Unknown';
    final price = product[kProductPrice] ?? '0';
    final stockQuantity = product[kProductQuantity] ?? '0';
    final imageUrl = product[kProductImageUrl]?.toString();

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
        onTap: stock <= 0 ? () {} : () => _selectProduct(product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ProductImageWidget(
                imageUrl: imageUrl,
                size: 60,
                fallbackIcon: Icons.inventory_2,
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
