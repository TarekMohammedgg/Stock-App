import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/secure_storage_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:table_calendar/table_calendar.dart';

Future<String> getDeviceNameID() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String? deviceName;
  String? deviceId;

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceName = "${androidInfo.name} ${androidInfo.model}";
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

  SecureStorageHelper.write(kDeviceInfoNameId, "$deviceName $deviceId");
  return "$deviceName $deviceId";
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
