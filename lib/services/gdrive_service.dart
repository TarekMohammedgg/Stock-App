import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Unified service for Google Drive integration using Apps Script
/// Provides image upload functionality with low-level and high-level operations
class GDriveService {
  // ==================== LOW-LEVEL UPLOAD OPERATIONS ====================

  /// Upload image to Google Drive (low-level)
  /// Returns the image URL if successful, null otherwise
  Future<String?> _uploadImageLowLevel(File imageFile) async {
    final String scriptUrl = CacheHelper.getData(kAppScriptUrl) ?? "";
    final String folderId = CacheHelper.getData(kDriveFolderId) ?? "";

    try {
      log('Converting image to Base64...');
      final fileBytes = await imageFile.openRead(0, 1024).first;
      final mimeType = lookupMimeType(imageFile.path, headerBytes: fileBytes);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      String fileName = p.basename(imageFile.path);

      Map<String, dynamic> body = {
        "folderId": folderId,
        "filename": fileName,
        "mimeType": mimeType ?? "image/jpeg",
        "base64": base64Image,
      };

      log('Uploading...');

      var request = http.Request('POST', Uri.parse(scriptUrl));
      request.body = jsonEncode(body);
      request.headers.addAll({"Content-Type": "application/json"});

      request.followRedirects = false;

      final streamedResponse = await request.send();

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 302 || response.statusCode == 301) {
        final String? redirectUrl = response.headers['location'];

        if (redirectUrl != null) {
          final jsonResponseRaw = await http.get(Uri.parse(redirectUrl));

          var jsonResponse = jsonDecode(jsonResponseRaw.body);

          if (jsonResponse['status'] == 'success') {
            log('✅ Upload Done Successfully!');
            final imageUrl = jsonResponse['fileUrl'];
            log('File URL: $imageUrl');
            return imageUrl;
          } else {
            log('❌ Script Error: ${jsonResponse['message']}');
            return null;
          }
        }
      } else if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          log('✅ Upload Done (Direct)!');
          final imageUrl = jsonResponse['fileUrl'];
          log('File URL: $imageUrl');
          return imageUrl;
        }
      } else {
        log('❌ HTTP Error: ${response.statusCode}');
        log('Body: ${response.body}');
      }
    } catch (e) {
      log('❌ Exception: $e');
    }

    return null;
  }

  // ==================== URL CONVERSION ====================

  /// Convert Google Drive URL to direct image URL
  ///
  /// Converts URLs from formats like:
  /// - https://drive.google.com/file/d/FILE_ID/view
  /// - https://drive.google.com/open?id=FILE_ID
  ///
  /// To direct image URL that returns raw image data:
  /// - https://drive.google.com/uc?export=download&id=FILE_ID
  ///
  /// This format returns the actual image file (.jpg, .png, etc.)
  static String? convertToDirectImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    try {
      // Already a direct download URL
      if (url.contains('uc?export=download') || url.contains('uc?id=')) {
        return url;
      }

      // Extract file ID from various Google Drive URL formats
      String? fileId;

      // Format: https://drive.google.com/file/d/FILE_ID/view
      if (url.contains('/file/d/')) {
        final regex = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
        final match = regex.firstMatch(url);
        fileId = match?.group(1);
      }
      // Format: https://drive.google.com/open?id=FILE_ID
      else if (url.contains('open?id=')) {
        final regex = RegExp(r'id=([a-zA-Z0-9_-]+)');
        final match = regex.firstMatch(url);
        fileId = match?.group(1);
      }
      // Format: Already has id parameter
      else if (url.contains('id=')) {
        final regex = RegExp(r'id=([a-zA-Z0-9_-]+)');
        final match = regex.firstMatch(url);
        fileId = match?.group(1);
      }

      // If we found a file ID, create direct download URL
      if (fileId != null && fileId.isNotEmpty) {
        // Use export=download to get raw image data
        final directUrl =
            'https://drive.google.com/uc?export=download&id=$fileId';
        log('🔄 Converted to download URL: $directUrl');
        return directUrl;
      }

      // Return original URL if we couldn't parse it
      log('⚠️ Could not parse URL, returning original: $url');
      return url;
    } catch (e) {
      log('Error converting URL: $e');
      return url;
    }
  }

  // ==================== HIGH-LEVEL OPERATIONS ====================

  /// Upload product image to Google Drive
  /// Returns the image URL if successful, null otherwise
  Future<String?> uploadProductImage(File imageFile) async {
    try {
      log('📤 Uploading image to Google Drive...');

      final imageUrl = await _uploadImageLowLevel(imageFile);

      if (imageUrl != null) {
        log('✅ Image uploaded successfully');
        return imageUrl;
      } else {
        log('❌ Failed to get image URL');
        return null;
      }
    } catch (e) {
      log('❌ Error uploading image: $e');
      return null;
    }
  }

  /// Upload multiple images to Google Drive
  /// Returns list of image URLs (null for failed uploads)
  Future<List<String?>> uploadMultipleImages(List<File> imageFiles) async {
    final results = <String?>[];

    for (final imageFile in imageFiles) {
      final imageUrl = await uploadProductImage(imageFile);
      results.add(imageUrl);
    }

    return results;
  }
}
