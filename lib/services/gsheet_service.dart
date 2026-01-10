import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/secure_storage_helper.dart';
import 'package:gsheets/gsheets.dart';

/// Unified service for Google Sheets integration using service account
/// Provides both high-level API and low-level operations for CRUD on Products, Sales, and Expired sheets
class GSheetService {
  // ==================== LOW-LEVEL GSHEET SETUP ====================

  static final String _credentials = dotenv.env['GSHEET_CREDENTIALS']!;

  static final GSheets _gsheets = GSheets(_credentials);
  static List dataFromSheet = [];

  // ignore: prefer_typing_uninitialized_variables
  static var _gsheetController;
  static Worksheet? _gsheetCrudUserDetails;

  bool _isInitialized = false;

  // ==================== INITIALIZATION ====================

  /// Initialize Google Sheets connection (low-level)
  static Future<void> gSheetInit({String? spreadsheetId}) async {
    final targetId = spreadsheetId!;
    _gsheetController = await _gsheets.spreadsheet(targetId);
    log("GSheet initialized with ID: $targetId");
  }

  /// Initialize Google Sheets connection (high-level)
  Future<void> initialize() async {
    if (_isInitialized) {
      log('ℹ️ GSheet already initialized');
      return;
    }

    try {
      final spreadsheetId = await SecureStorageHelper.read(kSpreadsheetId);
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
