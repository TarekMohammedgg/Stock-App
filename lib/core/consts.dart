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

// Google Sheets names
const kProducts = 'Products'; // Legacy sheet
const kExpired = 'Expired';
const kSales = "Sales"; // Legacy sheet
const kSpreadSheetName = "StockApp";

// Column headers for Products sheet
const List<String> kProductsHeaders = [
  kProductId,
  kProductBarcode,
  kProductName,
  kProductPrice,
  kProductQuantity,
  kProductImageUrl,
];

const List<String> kExpiredHeaders = [

] ;

const List<String> kSalesHeaders = [
  kSaleId,
  kSaleProductId,
  kSaleProductName,
  kSaleQuantity,
  kEmployeeUsernameHeader,

  kSaleCreatedDate,
];

// Stock level thresholds
const int kAdequateStockThreshold = 20;
const int kLowStockThreshold = 5;

const String kProductId = 'Id';
const String kProductBarcode = 'Barcode';
const String kProductName = 'Product Name';
const String kProductPrice = 'Product Price';
const String kProductQuantity = 'Product Quantity';
const String kProductImageUrl = 'ImageUrl';
const String kSaleId = 'Id';
const String kSaleProductId = 'Product Id';
const String kSaleProductName = 'Product Name';
const String kSaleProductPrice = 'Product Price';
const String kSaleQuantity = 'Sale Quantity';
const String kSaleCreatedDate = 'Created Date';
const String kSellQuantity = 'sellQuantity';
const String kEmployeeUsernameHeader = 'Employee Username';

/// Attendance Configurations
final double allowedRadiusInMeters = 100;
final double officeLat = 29.934596;
final double officeLong = 31.264948;
