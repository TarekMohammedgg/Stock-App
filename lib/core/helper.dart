import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter/foundation.dart'; // For kIsWeb

Future<String> getDeviceNameID() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String? deviceName;
  String? deviceId;

  try {
    if (kIsWeb) {
      WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
      deviceName = "${webInfo.browserName.name} on ${webInfo.platform}";
      deviceId = webInfo.userAgent ?? 'Unknown Web User Agent';
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceName = "${androidInfo.brand} ${androidInfo.model}";
      deviceId = androidInfo.id; // Unique Android ID
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.utsname.machine;
      deviceId = iosInfo.identifierForVendor; // Unique iOS ID
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      deviceName = windowsInfo.computerName;
      deviceId = windowsInfo.deviceId; // Unique Windows device ID
    }
  } catch (e) {
    log("Error getting device info: $e");
    deviceName = "Unknown Device";
    deviceId = "UnknownID";
  }

  final finalId = "$deviceName ${deviceId ?? ''}".trim();
  await CacheHelper.saveData(kDeviceInfoNameId, finalId);
  return finalId;
}

String formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

Future<bool> checkPermissions() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return false;
  }
  if (permission == LocationPermission.deniedForever) return false;
  return true;
}

getCurrentPosition() {
  final position = Geolocator.getCurrentPosition();
  return position;
}

Future<bool> getDistanceBetweenPositions({
  required Position currentPosition,
}) async {
  const double allowedRadiusInMeters = 100.0;
  const double officeLat = 29.934596;
  const double officeLong = 31.264948;

  final distance = Geolocator.distanceBetween(
    officeLat,
    officeLong,
    currentPosition.latitude,
    currentPosition.longitude,
  );
  log("distance is : $distance");

  return distance <= allowedRadiusInMeters;
}

String capitalize(String username) {
  if (username.isEmpty) {
    return username;
  }
  return username[0].toUpperCase() + username.substring(1).toLowerCase();
}

String getLanguageName(String code) {
  switch (code) {
    case 'ar':
      return 'العربية';
    case 'en':
    default:
      return 'English';
  }
}
