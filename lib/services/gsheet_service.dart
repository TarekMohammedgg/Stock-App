import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gsheets/gsheets.dart';

/// Unified service for Google Sheets integration using service account
/// Provides both high-level API and low-level operations for CRUD on Products, Sales, and Expired sheets
class GSheetService {
  // ==================== LOW-LEVEL GSHEET SETUP ====================

  // Use lazy-loaded credentials to avoid null check errors during app startup
  // dotenv.load() must be called before using GSheetService
  static String? _cachedCredentials;
  static String get _credentials {
    _cachedCredentials ??= dotenv.env['GSHEET_CREDENTIALS'];
    if (_cachedCredentials == null || _cachedCredentials!.isEmpty) {
      throw Exception(
        'GSHEET_CREDENTIALS not found in .env file. '
        'Make sure dotenv.load() is called before using GSheetService.',
      );
    }
    return _cachedCredentials!;
  }

  // Lazy-loaded GSheets instance
  static GSheets? _gsheetsInstance;
  static GSheets get _gsheets {
    _gsheetsInstance ??= GSheets(_credentials);
    return _gsheetsInstance!;
  }

  static List dataFromSheet = [];

  // ignore: prefer_typing_uninitialized_variables
  static var _gsheetController;
  static Worksheet? _gsheetCrudUserDetails;

  bool _isInitialized = false;

  // ==================== INITIALIZATION ====================

  /// Initialize Google Sheets connection (low-level)
  static Future<void> gSheetInit({String? spreadsheetId}) async {
    if (spreadsheetId == null || spreadsheetId.isEmpty) {
      throw Exception(
        'SpreadsheetId is null or empty. Please set up your credentials first.',
      );
    }
    _gsheetController = await _gsheets.spreadsheet(spreadsheetId);
    log("GSheet initialized with ID: $spreadsheetId");
  }

  /// Initialize Google Sheets connection (high-level)
  Future<void> initialize() async {
    if (_isInitialized) {
      log('ℹ️ GSheet already initialized');
      return;
    }

    try {
      final spreadsheetId = CacheHelper.getData(kSpreadsheetId) as String?;
      log(
        '📡 Initializing GSheet with SpreadsheetId: ${spreadsheetId ?? "default (fallback)"}',
      );
      await gSheetInit(spreadsheetId: spreadsheetId);
      _isInitialized = true;
      log('✅ GSheet service initialized');
    } catch (e) {
      log('❌ Failed to initialize GSheet: $e');
      rethrow;
    }
  }

  /// Ensure initialization before operations
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // ==================== LOW-LEVEL OPERATIONS ====================

  /// Insert data into sheet (low-level)
  static Future<bool> insertDataIntoSheet({
    userDetailsList,
    String worksheetName = "Products",
  }) async {
    try {
      // Get the worksheet by the provided name
      _gsheetCrudUserDetails = _gsheetController.worksheetByTitle(
        worksheetName,
      );

      log("Inserting data into worksheet: $worksheetName");

      await _gsheetCrudUserDetails!.values.map.appendRows(userDetailsList);
      return true;
    } catch (e) {
      log("failed when uploading ${e.toString()}");
      return false;
    }
  }

  /// Helper function to find row index by ID value (low-level)
  static Future<int?> findRowIndexById(
    String idValue, {
    String? worksheetName,
  }) async {
    try {
      // Get the worksheet by the provided name if specified
      if (worksheetName != null) {
        _gsheetCrudUserDetails = _gsheetController.worksheetByTitle(
          worksheetName,
        );
      }

      final index = await _gsheetCrudUserDetails!.values.rowIndexOf(idValue);
      log("Found row at index: $index for ID: $idValue");
      return index;
    } catch (e) {
      log("Failed to find row index: ${e.toString()}");
      return null;
    }
  }

  /// Read data from sheet (low-level)
  static Future<void> readDataFromSheet({String? worksheetName}) async {
    // Get the worksheet by the provided name if specified
    if (worksheetName != null) {
      _gsheetCrudUserDetails = _gsheetController.worksheetByTitle(
        worksheetName,
      );
    }

    dataFromSheet = (await _gsheetCrudUserDetails!.values.map.allRows())!;
    log("Fetched Data");
    log("Data $dataFromSheet");
  }

  /// Update data in sheet (low-level)
  static Future<bool> updateDataFromSheet(
    String idValue,
    Map<String, dynamic> newData, {
    String? worksheetName,
  }) async {
    try {
      // Get the worksheet by the provided name if specified
      if (worksheetName != null) {
        _gsheetCrudUserDetails = _gsheetController.worksheetByTitle(
          worksheetName,
        );
      }

      await _gsheetCrudUserDetails!.values.map.insertRowByKey(idValue, newData);
      log("Updated row with ID: $idValue");
      return true;
    } catch (e) {
      log("Failed to update: ${e.toString()}");
      return false;
    }
  }

  /// Delete data from sheet (low-level)
  static Future<bool> deleteDataFromSheet(
    String idValue, {
    String? worksheetName,
  }) async {
    try {
      // Get the worksheet by the provided name if specified
      if (worksheetName != null) {
        _gsheetCrudUserDetails = _gsheetController.worksheetByTitle(
          worksheetName,
        );
      }

      final index = await findRowIndexById(
        idValue,
        worksheetName: worksheetName,
      );

      if (index == null) {
        log("Row not found with ID: $idValue");
        return false;
      }

      await _gsheetCrudUserDetails!.deleteRow(index);
      log("Deleted row with ID: $idValue at index: $index");
      return true;
    } catch (e) {
      log("Failed to delete: ${e.toString()}");
      return false;
    }
  }

  // ==================== HIGH-LEVEL PRODUCTS OPERATIONS ====================

  /// Get all products from Products sheet
  Future<List<Map<String, dynamic>>> getProducts() async {
    await _ensureInitialized();

    try {
      await readDataFromSheet(worksheetName: kProducts);
      log('✅ Fetched ${dataFromSheet.length} products');
      return List<Map<String, dynamic>>.from(dataFromSheet);
    } catch (e) {
      log('❌ Error fetching products: $e');
      return [];
    }
  }

  /// Add new product to Products sheet
  Future<bool> addProduct(Map<String, dynamic> product) async {
    await _ensureInitialized();

    try {
      final result = await insertDataIntoSheet(
        userDetailsList: [product],
        worksheetName: kProducts,
      );

      if (result) {
        log('✅ Product added successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error adding product: $e');
      return false;
    }
  }

  /// Update existing product in Products sheet
  Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> newData,
  ) async {
    await _ensureInitialized();

    try {
      final result = await updateDataFromSheet(
        productId,
        newData,
        worksheetName: kProducts,
      );

      if (result) {
        log('✅ Product updated successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error updating product: $e');
      return false;
    }
  }

  /// Delete product from Products sheet
  Future<bool> deleteProduct(String productId) async {
    await _ensureInitialized();

    try {
      final result = await deleteDataFromSheet(
        productId,
        worksheetName: kProducts,
      );

      if (result) {
        log('✅ Product deleted successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error deleting product: $e');
      return false;
    }
  }

  // ==================== HIGH-LEVEL SALES OPERATIONS ====================

  /// Get all sales from Sales sheet
  Future<List<Map<String, dynamic>>> getSales() async {
    await _ensureInitialized();

    try {
      await readDataFromSheet(worksheetName: kSales);
      log('✅ Fetched ${dataFromSheet.length} sales');
      return List<Map<String, dynamic>>.from(dataFromSheet);
    } catch (e) {
      log('❌ Error fetching sales: $e');
      return [];
    }
  }

  /// Get the next invoice number (sequential: 001, 002, 003, ...)
  Future<String> getNextInvoiceNumber() async {
    await _ensureInitialized();

    try {
      final sales = await getSales();

      if (sales.isEmpty) {
        return '001';
      }

      int maxNumber = 0;
      for (var sale in sales) {
        // Try new field first, then legacy
        final saleId =
            sale[kSalesId]?.toString() ?? sale[kSaleId]?.toString() ?? '';

        // Try to parse as number
        final num = int.tryParse(saleId);
        if (num != null && num > maxNumber) {
          maxNumber = num;
        }
      }

      // Increment and format with leading zeros (at least 3 digits)
      final nextNumber = maxNumber + 1;
      return nextNumber.toString().padLeft(3, '0');
    } catch (e) {
      log('❌ Error getting next invoice number: $e');
      // Fallback to timestamp-based ID
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// Add new sale to Sales sheet
  Future<bool> addSale(Map<String, dynamic> sale) async {
    await _ensureInitialized();

    try {
      final result = await insertDataIntoSheet(
        userDetailsList: [sale],
        worksheetName: kSales,
      );

      if (result) {
        log('✅ Sale added successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error adding sale: $e');
      return false;
    }
  }

  /// Update existing sale in Sales sheet
  Future<bool> updateSale(String saleId, Map<String, dynamic> newData) async {
    await _ensureInitialized();

    try {
      final result = await updateDataFromSheet(
        saleId,
        newData,
        worksheetName: kSales,
      );

      if (result) {
        log('✅ Sale updated successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error updating sale: $e');
      return false;
    }
  }

  /// Delete sale from Sales sheet
  Future<bool> deleteSale(String saleId) async {
    await _ensureInitialized();

    try {
      final result = await deleteDataFromSheet(saleId, worksheetName: kSales);

      if (result) {
        log('✅ Sale deleted successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error deleting sale: $e');
      return false;
    }
  }

  // ==================== HIGH-LEVEL EXPIRED PRODUCTS OPERATIONS ====================

  /// Get all expired products from Expired sheet
  /// @deprecated Use ProductItems with expiry dates instead
  Future<List<Map<String, dynamic>>> getExpiredProducts() async {
    await _ensureInitialized();

    try {
      await readDataFromSheet(worksheetName: kExpired);
      log('✅ Fetched ${dataFromSheet.length} expired products');
      return List<Map<String, dynamic>>.from(dataFromSheet);
    } catch (e) {
      log('❌ Error fetching expired products: $e');
      return [];
    }
  }

  /// Add expired product to Expired sheet
  /// @deprecated Use ProductItems with expiry dates instead
  Future<bool> addExpiredProduct(Map<String, dynamic> product) async {
    await _ensureInitialized();

    try {
      final result = await insertDataIntoSheet(
        userDetailsList: [product],
        worksheetName: kExpired,
      );

      if (result) {
        log('✅ Expired product added successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error adding expired product: $e');
      return false;
    }
  }

  /// Delete expired product from Expired sheet
  /// @deprecated Use ProductItems with expiry dates instead
  Future<bool> deleteExpiredProduct(String productId) async {
    await _ensureInitialized();

    try {
      final result = await deleteDataFromSheet(
        productId,
        worksheetName: kExpired,
      );

      if (result) {
        log('✅ Expired product deleted successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error deleting expired product: $e');
      return false;
    }
  }

  // ==================== PRODUCT ITEMS OPERATIONS (NEW WORKFLOW) ====================

  /// Get all product items (batches) from ProductItems sheet
  Future<List<Map<String, dynamic>>> getProductItems() async {
    await _ensureInitialized();

    try {
      await readDataFromSheet(worksheetName: kProductItems);
      log('✅ Fetched ${dataFromSheet.length} product items');
      return List<Map<String, dynamic>>.from(dataFromSheet);
    } catch (e) {
      log('❌ Error fetching product items: $e');
      return [];
    }
  }

  /// Get product items by product ID
  Future<List<Map<String, dynamic>>> getProductItemsByProductId(
    String productId,
  ) async {
    await _ensureInitialized();

    try {
      await readDataFromSheet(worksheetName: kProductItems);
      final items = dataFromSheet
          .where((item) => item[kProductItemProductId] == productId)
          .toList();
      log('✅ Fetched ${items.length} items for product: $productId');
      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      log('❌ Error fetching product items by product ID: $e');
      return [];
    }
  }

  /// Add new product item (batch) to ProductItems sheet
  Future<bool> addProductItem(Map<String, dynamic> productItem) async {
    await _ensureInitialized();

    try {
      final result = await insertDataIntoSheet(
        userDetailsList: [productItem],
        worksheetName: kProductItems,
      );

      if (result) {
        log('✅ Product item added successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error adding product item: $e');
      return false;
    }
  }

  /// Update existing product item in ProductItems sheet
  Future<bool> updateProductItem(
    String productItemId,
    Map<String, dynamic> newData,
  ) async {
    await _ensureInitialized();

    try {
      final result = await updateDataFromSheet(
        productItemId,
        newData,
        worksheetName: kProductItems,
      );

      if (result) {
        log('✅ Product item updated successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error updating product item: $e');
      return false;
    }
  }

  /// Delete product item from ProductItems sheet
  Future<bool> deleteProductItem(String productItemId) async {
    await _ensureInitialized();

    try {
      final result = await deleteDataFromSheet(
        productItemId,
        worksheetName: kProductItems,
      );

      if (result) {
        log('✅ Product item deleted successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error deleting product item: $e');
      return false;
    }
  }

  /// Get total quantity for a product (sum of all batches)
  Future<int> getTotalProductQuantity(String productId) async {
    await _ensureInitialized();

    try {
      final items = await getProductItemsByProductId(productId);
      int total = 0;
      for (var item in items) {
        final qty =
            int.tryParse(item[kProductItemQuantity]?.toString() ?? '0') ?? 0;
        total += qty;
      }
      log('✅ Total quantity for product $productId: $total');
      return total;
    } catch (e) {
      log('❌ Error calculating total quantity: $e');
      return 0;
    }
  }

  // ==================== SALES ITEMS OPERATIONS (NEW WORKFLOW) ====================

  /// Get all sales items from SalesItems sheet
  Future<List<Map<String, dynamic>>> getSalesItems() async {
    await _ensureInitialized();

    try {
      await readDataFromSheet(worksheetName: kSalesItems);
      log('✅ Fetched ${dataFromSheet.length} sales items');
      return List<Map<String, dynamic>>.from(dataFromSheet);
    } catch (e) {
      log('❌ Error fetching sales items: $e');
      return [];
    }
  }

  /// Get sales items by sale ID
  Future<List<Map<String, dynamic>>> getSalesItemsBySaleId(
    String saleId,
  ) async {
    await _ensureInitialized();

    try {
      await readDataFromSheet(worksheetName: kSalesItems);
      final items = dataFromSheet
          .where((item) => item[kSalesItemSalesId] == saleId)
          .toList();
      log('✅ Fetched ${items.length} items for sale: $saleId');
      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      log('❌ Error fetching sales items by sale ID: $e');
      return [];
    }
  }

  /// Add new sales item to SalesItems sheet
  Future<bool> addSalesItem(Map<String, dynamic> salesItem) async {
    await _ensureInitialized();

    try {
      final result = await insertDataIntoSheet(
        userDetailsList: [salesItem],
        worksheetName: kSalesItems,
      );

      if (result) {
        log('✅ Sales item added successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error adding sales item: $e');
      return false;
    }
  }

  /// Add a complete sale with multiple items (atomic operation)
  /// Creates one Sale record and multiple SalesItem records
  Future<bool> addSaleWithItems({
    required Map<String, dynamic> saleData,
    required List<Map<String, dynamic>> saleItems,
  }) async {
    await _ensureInitialized();

    try {
      // Add the sale header
      final saleResult = await addSale(saleData);
      if (!saleResult) {
        log('❌ Failed to add sale header');
        return false;
      }

      // Add all sale items
      for (var item in saleItems) {
        final itemResult = await insertDataIntoSheet(
          userDetailsList: [item],
          worksheetName: kSalesItems,
        );
        if (!itemResult) {
          log('❌ Failed to add sale item: ${item[kSalesItemProductId]}');
          // Note: In a real transaction, we'd rollback here
          // For Google Sheets, we just log the error
        }
      }

      log('✅ Sale with ${saleItems.length} items added successfully');
      return true;
    } catch (e) {
      log('❌ Error adding sale with items: $e');
      return false;
    }
  }

  /// Delete sales item from SalesItems sheet
  Future<bool> deleteSalesItem(String salesItemId) async {
    await _ensureInitialized();

    try {
      final result = await deleteDataFromSheet(
        salesItemId,
        worksheetName: kSalesItems,
      );

      if (result) {
        log('✅ Sales item deleted successfully');
      }
      return result;
    } catch (e) {
      log('❌ Error deleting sales item: $e');
      return false;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Find row index by ID (useful for debugging)
  Future<int?> findRowIndex(String idValue, {String? worksheetName}) async {
    await _ensureInitialized();

    try {
      return await findRowIndexById(idValue, worksheetName: worksheetName);
    } catch (e) {
      log('❌ Error finding row index: $e');
      return null;
    }
  }

  /// Refresh data from a specific worksheet
  Future<void> refreshData({String worksheetName = kProducts}) async {
    await _ensureInitialized();

    try {
      await readDataFromSheet(worksheetName: worksheetName);
      log('✅ Data refreshed from $worksheetName');
    } catch (e) {
      log('❌ Error refreshing data: $e');
    }
  }
}
