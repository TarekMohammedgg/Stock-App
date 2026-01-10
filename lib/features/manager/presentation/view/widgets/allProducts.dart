import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/permission_helper.dart';
import 'package:gdrive_tutorial/core/secure_storage_helper.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/credential_screen.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/product_card.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/product_dialog.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';

class AllProducts extends StatefulWidget {
  static String id = "AllProducts ";
  const AllProducts({super.key});

  @override
  State<AllProducts> createState() => _AllProductsState();
}

class _AllProductsState extends State<AllProducts> {
  bool isLoading = false;
  List<Map<String, dynamic>> products = [];
  final GSheetService gSheetService = GSheetService();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchData(),
    );
    _checkCredentialsAndLoad();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          "All Products".tr(),
          style: TextStyle(
            color: colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(slivers: [_buildBody()]),
    );
  }

  Future<void> _checkCredentialsAndLoad() async {
    // Check if credentials exist in secure storage
    final spreadsheetId = await SecureStorageHelper.read(kSpreadsheetId);
    final folderId = await SecureStorageHelper.read(kDriveFolderId);
    final appScriptUrl = await SecureStorageHelper.read(kAppScriptUrl);

    // If any credential is missing or empty, navigate to credential screen
    if (spreadsheetId == null ||
        spreadsheetId.isEmpty ||
        folderId == null ||
        folderId.isEmpty ||
        appScriptUrl == null ||
        appScriptUrl.isEmpty) {
      log('⚠️ Manager credentials missing, navigating to credential screen');

      if (mounted) {
        final username = CacheHelper.getData(kUsername) ?? '';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CredentialScreen(username: username),
          ),
        );
      }
      return;
    }

    // Credentials exist, proceed with loading products
    _loadProducts();
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

  Future<void> _loadProducts() async {
    log('🔄 Starting to load products...');
    setState(() => isLoading = true);

    try {
      log('📡 Initializing GSheet service...');
      await gSheetService.initialize();

      log('📥 Fetching products from Google Sheets...');
      final loadedProducts = await gSheetService.getProducts();

      log('✅ Received ${loadedProducts.length} products from service');

      // Log each product for debugging
      for (int i = 0; i < loadedProducts.length; i++) {
        log('Product $i: ${loadedProducts[i]}');
      }

      setState(() {
        products = loadedProducts;
        isLoading = false;
      });

      log('✅ Products loaded successfully. Total: ${products.length}');
    } catch (e, stackTrace) {
      log('❌ Error loading products: $e');
      log('Stack trace: $stackTrace');
      setState(() => isLoading = false);
      _showErrorSnackBar('${'Failed to load products'.tr()}: $e');
    }
  }

  Future<void> _fetchData() async {
    try {
      log('🔄 Auto-refreshing products...');
      final loadedProducts = await gSheetService.getProducts();

      setState(() {
        products = loadedProducts;
      });

      log('✅ Auto-refresh complete. Total: ${products.length}');
    } catch (e) {
      log('❌ Auto-refresh error: $e');
    }
  }

  Widget _buildBody() {
    if (isLoading && products.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    // Get filter argument
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool filterLowStock = args?['filterLowStock'] ?? false;

    // Filter products
    final displayProducts = products.where((p) {
      final name = p[kProductName]?.toString() ?? '';
      if (name.isEmpty) return false; // Ignore empty rows

      if (filterLowStock) {
        final qty = int.tryParse(p[kProductQuantity]?.toString() ?? '0') ?? 0;
        return qty <= kLowStockThreshold;
      }
      return true;
    }).toList();

    if (displayProducts.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(
          message: filterLowStock
              ? "No items with low stock".tr()
              : "No products in inventory".tr(),
          icon: filterLowStock
              ? Icons.check_circle_outline
              : Icons.inventory_2_outlined,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = displayProducts[index];

          return ProductCard(
            product: product,
            onEdit: () => _showEditProductDialog(product),
            onDelete: () =>
                _deleteProduct(product[kProductId]?.toString() ?? ''),
          );
        }, childCount: displayProducts.length),
      ),
    );
  }

  Widget _buildEmptyState({String? message, IconData? icon}) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.inventory_2_outlined,
            size: 80,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'No products found'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) =>
          ProductDialog(product: product, onSave: () => _loadProducts()),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    // Check permission first
    final hasPermission = await PermissionHelper.canDeleteProduct();
    if (!hasPermission) {
      _showErrorSnackBar('You do not have permission to delete products'.tr());
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'.tr()),
        content: Text('Are you sure you want to delete this product?'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await gSheetService.initialize();
      final success = await gSheetService.deleteProduct(productId);

      if (success) {
        _showSuccessSnackBar('Product deleted successfully'.tr());
        _loadProducts();
      } else {
        _showErrorSnackBar('Failed to delete product'.tr());
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }
}
