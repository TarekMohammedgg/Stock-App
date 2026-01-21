/// Google API endpoints and constants
library;

class GoogleApiConstants {
  GoogleApiConstants._();

  // ==================== Auth Client ====================
  // static String? serverClientId = dotenv.env['SERVERCLIENT_ID'];
  static List<String> scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/spreadsheets',
  ];
  // ==================== Base URLs ====================
  static const String driveBaseUrl = 'https://www.googleapis.com/drive/v3';
  static const String driveUploadBaseUrl =
      'https://www.googleapis.com/upload/drive/v3';
  static const String sheetsBaseUrl = 'https://sheets.googleapis.com/v4';

  // ==================== Google Drive Endpoints ====================
  /// List/search files endpoint
  static const String driveFiles = '$driveBaseUrl/files';

  /// Upload file with multipart
  static const String driveUploadMultipart =
      '$driveUploadBaseUrl/files?uploadType=multipart';

  /// Get file link template
  static String getDriveFileLink(String fileId) =>
      'https://drive.google.com/file/d/$fileId/view?usp=sharing';

  // ==================== Google Sheets Endpoints ====================
  /// Create spreadsheet
  static const String createSpreadsheet = '$sheetsBaseUrl/spreadsheets';

  /// Get spreadsheet metadata
  static String getSpreadsheet(String spreadsheetId) =>
      '$sheetsBaseUrl/spreadsheets/$spreadsheetId';

  /// Get/update values in a range
  static String getSheetValues(String spreadsheetId, String range) =>
      '$sheetsBaseUrl/spreadsheets/$spreadsheetId/values/$range';

  /// Append values to sheet
  static String appendSheetValues(String spreadsheetId, String range) =>
      '$sheetsBaseUrl/spreadsheets/$spreadsheetId/values/$range:append';

  /// Clear values in a range
  static String clearSheetValues(String spreadsheetId, String range) =>
      '$sheetsBaseUrl/spreadsheets/$spreadsheetId/values/$range:clear';

  /// Batch update spreadsheet
  static String batchUpdateSpreadsheet(String spreadsheetId) =>
      '$sheetsBaseUrl/spreadsheets/$spreadsheetId:batchUpdate';

  // ==================== MIME Types ====================
  static const String mimeTypeFolder = 'application/vnd.google-apps.folder';
  static const String mimeTypeSpreadsheet =
      'application/vnd.google-apps.spreadsheet';
  static const String mimeTypeJson = 'application/json';
  static const String mimeTypeJsonUtf8 = 'application/json; charset=UTF-8';
  static const String mimeTypeMultipartRelated = 'multipart/related';
  static const String mimeTypeOctetStream = 'application/octet-stream';

  // ==================== Query Parameters ====================
  static const String queryParamFields = 'fields';
  static const String queryParamQ = 'q';
  static const String queryParamValueInputOption = 'valueInputOption';
  static const String queryParamInsertDataOption = 'insertDataOption';

  // ==================== Value Input Options ====================
  static const String valueInputOptionRaw = 'RAW';
  static const String valueInputOptionUserEntered = 'USER_ENTERED';

  // ==================== Insert Data Options ====================
  static const String insertDataOptionInsertRows = 'INSERT_ROWS';
  static const String insertDataOptionOverwrite = 'OVERWRITE';

  // ==================== Header Keys ====================
  static const String headerAuthorization = 'Authorization';
  static const String headerContentType = 'Content-Type';

  /// Generate Bearer token header value
  static String getBearerToken(String accessToken) => 'Bearer $accessToken';

  // ==================== Query Builders ====================
  /// Build query for finding folder by name
  static String buildFolderQuery(String folderName, {String? parentId}) {
    String escapedName = folderName.replaceAll("'", "\\'");
    String query =
        "mimeType='$mimeTypeFolder' and name='$escapedName' and trashed=false";
    if (parentId != null) {
      query += " and '$parentId' in parents";
    }
    return query;
  }

  /// Build query for finding spreadsheet by name
  static String buildSpreadsheetQuery(String spreadsheetName) {
    String escapedName = spreadsheetName.replaceAll("'", "\\'");
    return "mimeType='$mimeTypeSpreadsheet' and name='$escapedName' and trashed=false";
  }

  // ==================== Default Values ====================
  static const String defaultSheetName = 'Sheet1';
  static const String defaultRangeAllColumns = 'A:Z';
  static const String defaultRangeFromA = 'A:A';
  static const String defaultDataStartRow = 'A2:Z'; // Excludes header row
}
