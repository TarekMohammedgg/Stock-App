// Google Sheets and Drive Configuration
const kFirebaseStoreActiveSessions = "activeSessions";
const kDeviceInfoNameId = "DeviceNameId";
const kDeviceInfoLoginTime = "loginTime";
const kDeviceInfoLastActive = "lastActive";
const kGoogleImageUrl =
    "https://www.freepnglogos.com/uploads/google-logo-png/google-logo-png-webinar-optimizing-for-success-google-business-webinar-13.png";

// Secure Cache Helper keys
const String kSpreadsheetId = 'SpreadsheetId';
const String kDriveFolderId = 'DriveFolderId';
const String kAppScriptUrl = 'AppScriptUrl';
const String kEmail = 'Email';
const String kIsLogin = 'IsLogin';
const String kEmployeeId = 'EmployeeId';
const String kUsername = 'Username';
const String kDisplayName = 'DisplayName';
const String kUserType = 'UserType';
const String kIsShowOnboarding = 'isShowOnboarding';
const String kThemeMode = 'ThemeMode';

// Manager-Employee Authentication
const kManagersCollection = "managers";
const kEmployeesCollection = "employees";

// Manager Fields
const kManagerEmail = "email";
const kManagerDisplayName = "displayName";
const kManagerPhotoUrl = "photoUrl";
const kManagerAccessToken = "accessToken";
const kManagerRefreshToken = "refreshToken";
const kManagerTokenExpiresAt = "tokenExpiresAt";
const kManagerSpreadsheetId = "spreadsheetId";
const kManagerDriveFolderId = "driveFolderId";
const kManagerAppScriptUrl = "appScriptUrl";
const kManagerCreatedAt = "createdAt";
const kManagerLastTokenRefresh = "lastTokenRefresh";
const kRoles = "Roles";
const kPermissions = "Permissions";

// Work Location - Firestore fields (map inside manager document)
const kManagerWorkLocation = "workLocation";
const kWorkLatitude = "latitude";
const kWorkLongitude = "longitude";

// Work Location - SharedPrefs keys for quick loading
const kPrefWorkLatitude = "work_latitude";
const kPrefWorkLongitude = "work_longitude";

// Manager Activation Status - SharedPrefs key
const kPrefManagerIsActive = "manager_is_active";
const kPrefEmployeeIsActive = "employee_is_active";

// Employee Fields
const kEmployeeIdField = "employeeId";
const kEmployeeUsername = "username";
const kEmployeePassword = "password";
const kEmployeeDisplayName = "displayName";
const kEmployeeManagerEmail = "managerEmail";
const kEmployeeRoles = "roles";
const kEmployeePermissions = "permissions";
const kEmployeeIsActive = "isActive";
const kEmployeeCreatedAt = "createdAt";
const kEmployeeCreatedBy = "createdBy";
const kEmployeeLastLogin = "lastLogin";
const kAttendance = "attendance";
const kCheckInTime = "checkInTime";
const kCheckOutTime = "checkOutTime";
const kTotalHours = "totalHours";
const kCheckInLocation = "checkInLocation";
const kLatitude = "latitude";
const kLongitude = "longitude";
const kDate = "date";
const kStatus = "status";
const kCompleted = "completed";

// User Types
const kUserTypeManager = "manager";
const kUserTypeEmployee = "employee";

// Permission Keys for Employee Access Control
const kPermissionAddProduct = "canAddProduct";
const kPermissionManageInventory = "canManageInventory";
const kPermissionDeleteProduct = "canDeleteProduct";

// ==================== Google Sheets Worksheet Names ====================
const kSpreadSheetName = "Stock App";
const kProducts = 'Products';
const kProductItems = 'ProductItems';
const kSales = 'Sales';
const kSalesItems = 'SalesItems';

// ==================== Products Columns ====================
// Basic product information (no quantity here - quantity is in ProductItems)
const String kProductId = 'Product Id';
const String kProductBarcode = 'Product Barcode';
const String kProductName = 'Product Name';
const String kProductPrice = 'Product Price'; // Selling price

const List<String> kProductsHeaders = [
  kProductId,
  kProductBarcode,
  kProductName,
  kProductPrice,
];

// ==================== ProductItems Columns ====================
// Batches of products with purchase details
const String kProductItemId = 'Product Item Id';
const String kProductItemProductId = 'Product Id';
const String kProductItemBuyPrice = 'Buy Price';
const String kProductItemQuantity = 'Product Quantity';
const String kProductItemCreatedAt = 'Created At';
const String kProductItemExpiredAt = 'Expired At';

const List<String> kProductItemsHeaders = [
  kProductItemId,
  kProductItemProductId,
  kProductItemBuyPrice,
  kProductItemQuantity,
  kProductItemCreatedAt,
  kProductItemExpiredAt,
];

// ==================== Sales Columns ====================
// Invoice/Order header
const String kSalesId = 'Sales Id';
const String kSalesTotalPrice = 'Sales Total Price';
const String kSalesCreatedDate = 'Created Date';
const String kSalesEmployeeUsername = 'Employee Username';

const List<String> kSalesHeaders = [
  kSalesId,
  kSalesTotalPrice,
  kSalesCreatedDate,
  kSalesEmployeeUsername,
];

// ==================== SalesItems Columns ====================
// Invoice/Order line items
const String kSalesItemId = 'Sales Item Id';
const String kSalesItemSalesId = 'Sales Id';
const String kSalesItemProductId = 'Product Id';
const String kSalesItemQuantity = 'Sales Quantity';
const String kSalesItemPrice = 'Sales Price'; // Price at time of sale

const List<String> kSalesItemsHeaders = [
  kSalesItemId,
  kSalesItemSalesId,
  kSalesItemProductId,
  kSalesItemQuantity,
  kSalesItemPrice,
];

// ==================== Invoice PDF Headers ====================
// Table headers for invoice PDF generation
const String kInvoiceHeaderDescription = 'Description';
const String kInvoiceHeaderDate = 'Date';
const String kInvoiceHeaderQuantity = 'Quantity';
const String kInvoiceHeaderUnitPrice = 'Unit Price';
const String kInvoiceHeaderTotal = 'Total';

const List<String> kInvoiceTableHeaders = [
  kInvoiceHeaderDescription,
  kInvoiceHeaderDate,
  kInvoiceHeaderQuantity,
  kInvoiceHeaderUnitPrice,
  kInvoiceHeaderTotal,
];

// Invoice info labels
const String kInvoiceLabelNumber = 'Invoice Number:';
const String kInvoiceLabelDate = 'Invoice Date:';
const String kInvoiceLabelPaymentTerms = 'Payment Terms:';
const String kInvoiceLabelDueDate = 'Due Date:';

// Invoice totals labels
const String kInvoiceLabelNetTotal = 'Net total';
const String kInvoiceLabelTotalAmountDue = 'Total amount due';

// Invoice footer labels
const String kInvoiceLabelAddress = 'Address';
const String kInvoiceLabelPaypal = 'Paypal';

// ==================== Stock Level Thresholds ====================
const int kAdequateStockThreshold = 20;
const int kLowStockThreshold = 5;

/// Attendance Configurations
final double allowedRadiusInMeters = 100;
final double officeLat = 29.934596;
final double officeLong = 31.264948;

// ==================== LEGACY CONSTANTS (DEPRECATED) ====================
// These constants are kept for backward compatibility with existing screens.
// They will be removed once all screens are migrated to the new workflow.
// TODO: Remove these after migrating all screens to new workflow

/// @deprecated Use kProductItemQuantity instead
const String kProductQuantity = 'Product Quantity';

/// @deprecated Image upload is disabled
const String kProductImageUrl = 'ImageUrl';

/// @deprecated Use kSalesId instead
const String kSaleId = 'Id';

/// @deprecated Use kSalesItemProductId instead
const String kSaleProductId = 'Product Id';

/// @deprecated Use product[kProductName] instead
const String kSaleProductName = 'Product Name';

/// @deprecated Use kSalesItemPrice instead
const String kSaleProductPrice = 'Product Price';

/// @deprecated Use kSalesItemQuantity instead
const String kSaleQuantity = 'Sale Quantity';

/// @deprecated Use kSalesCreatedDate instead
const String kSaleCreatedDate = 'Created Date';

/// @deprecated Use kSalesItemQuantity instead
const String kSellQuantity = 'sellQuantity';

/// @deprecated Use kSalesEmployeeUsername instead
const String kEmployeeUsernameHeader = 'Employee Username';

/// @deprecated Expired sheet is no longer used
const String kExpired = 'Expired';
