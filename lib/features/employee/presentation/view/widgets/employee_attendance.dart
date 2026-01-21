import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';

class EmployeeAttendance extends StatefulWidget {
  static const String id = 'employee_attendance';
  const EmployeeAttendance({super.key});

  @override
  State<EmployeeAttendance> createState() => _EmployeeAttendanceState();
}

class _EmployeeAttendanceState extends State<EmployeeAttendance> {
  // --- State Variables ---
  DateTime? checkInTime;
  DateTime? checkOutTime;
  bool isCheckedIn = false;
  bool isLoadingLocation = false;
  String locationStatus = '';
  String? workedHours;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> attendanceHistory = {};
  String? employeeId;
  bool isDataLoaded = false;

  // Work location from manager (loaded from SharedPrefs)
  double? _workLatitude;
  double? _workLongitude;

  @override
  void initState() {
    super.initState();
    _initializeAttendance();
  }

  /// 1. FIX: Reset all variables before loading new data
  void _resetLocalState() {
    setState(() {
      checkInTime = null;
      checkOutTime = null;
      isCheckedIn = false;
      workedHours = null;
      locationStatus = 'Loading data...'.tr();
      isDataLoaded = false;
    });
  }

  Future<void> _initializeAttendance() async {
    // Call the reset function first!
    _resetLocalState();

    try {
      employeeId = CacheHelper.getData(kEmployeeId);

      if (employeeId == null || employeeId!.isEmpty) {
        log('⚠️ Employee ID not found in cache');
        setState(() {
          locationStatus = 'Employee ID not found. Please login again.'.tr();
          isDataLoaded = true;
        });
        return;
      }

      // Load work location from SharedPrefs (saved during employee login)
      _workLatitude = CacheHelper.getData(kPrefWorkLatitude);
      _workLongitude = CacheHelper.getData(kPrefWorkLongitude);

      if (_workLatitude == null || _workLongitude == null) {
        log('⚠️ Work location not found in cache');
        setState(() {
          locationStatus = 'Work location not configured. Contact your manager.'
              .tr();
          isDataLoaded = true;
        });
        return;
      }

      log('📍 Work location loaded: $_workLatitude, $_workLongitude');

      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      log('📅 Loading attendance for: $today, Employee: $employeeId');

      DocumentSnapshot employeeDoc = await _firestore
          .collection(kEmployeesCollection)
          .doc(employeeId)
          .get();

      if (employeeDoc.exists) {
        Map<String, dynamic>? data =
            employeeDoc.data() as Map<String, dynamic>?;

        if (data != null && data[kAttendance] != null) {
          attendanceHistory = Map<String, dynamic>.from(data[kAttendance]);

          // Check if today's attendance exists
          if (attendanceHistory.containsKey(today)) {
            Map<String, dynamic> todayData = attendanceHistory[today];

            setState(() {
              if (todayData[kCheckInTime] != null) {
                checkInTime = (todayData[kCheckInTime] as Timestamp).toDate();
                // If there is no checkout time, we are currently checked in
                isCheckedIn = todayData[kCheckOutTime] == null;
              }

              if (todayData[kCheckOutTime] != null) {
                checkOutTime = (todayData[kCheckOutTime] as Timestamp).toDate();
                isCheckedIn = false;
                workedHours = _calculateWorkedHours(
                  start: checkInTime,
                  end: checkOutTime,
                );
              }

              locationStatus = 'Previous attendance loaded'.tr();
              isDataLoaded = true;
            });
            log('✅ Today\'s attendance loaded');
          } else {
            // 2. FIX: logic for "New Day"
            // If the key doesn't exist, the variables (checkInTime/checkOutTime)
            // remain null because we called _resetLocalState() at the top.
            log('ℹ️ No attendance for today');
            setState(() {
              locationStatus = 'Ready to check in'.tr();
              isDataLoaded = true;
            });
          }
        } else {
          log('ℹ️ No attendance field found');
          setState(() {
            isDataLoaded = true;
          });
        }
      } else {
        log('⚠️ Employee document not found');
        setState(() {
          locationStatus = 'Employee record not found'.tr();
          isDataLoaded = true;
        });
      }
    } catch (e) {
      log('❌ Error loading attendance: $e');
      setState(() {
        locationStatus = 'Failed to load attendance data'.tr();
        isDataLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _uploadAttendanceHistory();
    super.dispose();
  }

  Future<void> _uploadAttendanceHistory() async {
    if (employeeId == null || attendanceHistory.isEmpty) return;

    try {
      await _firestore.collection(kEmployeesCollection).doc(employeeId).set({
        kAttendance: attendanceHistory,
      }, SetOptions(merge: true));
      log('✅ Attendance history uploaded successfully');
    } catch (e) {
      log('❌ Error uploading attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (!isDataLoaded) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Attendance',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          iconTheme: IconThemeData(color: colorScheme.onSurface),
        ),
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Employee Attendance'.tr(),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: _initializeAttendance,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateCard(),
            const SizedBox(height: 20),
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildLocationStatus(),
            const SizedBox(height: 30),
            _buildActionButton(),
            const SizedBox(height: 30),
            _buildTimeDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              DateFormat('EEEE').format(DateTime.now()),
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, yyyy').format(DateTime.now()),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    Color statusColor = isCheckedIn ? colorScheme.secondary : Colors.orange;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCheckedIn ? Icons.check_circle : Icons.access_time,
              color: statusColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              isCheckedIn ? 'Checked In'.tr() : 'Not Checked In'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatus() {
    if (locationStatus.isEmpty) return const SizedBox.shrink();
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    bool isSuccess =
        locationStatus.contains('verified') ||
        locationStatus.contains('successfully') ||
        locationStatus.contains('loaded') ||
        locationStatus.contains('Ready');

    return Card(
      elevation: 0,
      color: isSuccess
          ? colorScheme.secondary.withOpacity(0.05)
          : colorScheme.error.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: (isSuccess ? colorScheme.secondary : colorScheme.error)
              .withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.location_on : Icons.location_off,
              color: isSuccess ? colorScheme.secondary : colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                locationStatus,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (checkOutTime != null) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.lock_clock),
        label: Text(
          'Attendance Completed Today'.tr(),
          style: TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoadingLocation
          ? null
          : (isCheckedIn ? _handleCheckOut : _handleCheckIn),
      icon: isLoadingLocation
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : Icon(
              isCheckedIn ? Icons.logout : Icons.login,
              color: colorScheme.onPrimary,
            ),
      label: Text(
        isLoadingLocation
            ? 'Verifying Location...'.tr()
            : (isCheckedIn ? 'Check Out'.tr() : 'Check In'.tr()),
        style: TextStyle(fontSize: 18, color: colorScheme.onPrimary),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCheckedIn
            ? colorScheme.error
            : colorScheme.secondary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildTimeDetails() {
    if (checkInTime == null && checkOutTime == null) {
      return const SizedBox.shrink();
    }
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Details'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const Divider(height: 24),
            if (checkInTime != null) ...[
              _buildTimeRow(
                'Check In'.tr(),
                DateFormat('hh:mm a').format(checkInTime!),
                Icons.login,
                colorScheme.secondary,
              ),
              const SizedBox(height: 12),
            ],
            if (checkOutTime != null) ...[
              _buildTimeRow(
                'Check Out'.tr(),
                DateFormat('hh:mm a').format(checkOutTime!),
                Icons.logout,
                colorScheme.error,
              ),
              const SizedBox(height: 12),
            ],
            if (workedHours != null) ...[
              const Divider(),
              const SizedBox(height: 12),
              _buildTimeRow(
                'Total Hours'.tr(),
                workedHours!,
                Icons.timer,
                colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, String time, IconData icon, Color color) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const Spacer(),
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _handleCheckIn() async {
    setState(() {
      isLoadingLocation = true;
      locationStatus = '';
    });

    bool isOnSite = await _verifyLocation(
      allowedRadiusInMeters: allowedRadiusInMeters,
      officeLat: officeLat,
      officeLong: officeLong,
    );

    if (isOnSite) {
      DateTime now = DateTime.now();
      String today = DateFormat('yyyy-MM-dd').format(now);

      setState(() {
        checkInTime = now;
        isCheckedIn = true;
        locationStatus = 'Location verified. Check-in successful!'.tr();
        isLoadingLocation = false;
      });

      attendanceHistory[today] = {
        kCheckInTime: Timestamp.fromDate(now),
        kCheckInLocation: {kLatitude: officeLat, kLongitude: officeLong},
        kDate: today,
      };

      log('✅ Check-in recorded in memory');
      // _showSuccessDialog('Checked In Successfully!');
    } else {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  Future<void> _handleCheckOut() async {
    setState(() {
      isLoadingLocation = true;
      locationStatus = '';
    });

    bool isOnSite = await _verifyLocation(
      allowedRadiusInMeters: allowedRadiusInMeters,
      officeLat: officeLat,
      officeLong: officeLong,
    );

    if (isOnSite) {
      DateTime now = DateTime.now();
      String today = DateFormat('yyyy-MM-dd').format(now);

      String calculatedHours = _calculateWorkedHours(
        start: checkInTime,
        end: now,
      );

      setState(() {
        checkOutTime = now;
        isCheckedIn = false;
        workedHours = calculatedHours;
        locationStatus = 'Location verified. Check-out successful!'.tr();
        isLoadingLocation = false;
      });

      if (attendanceHistory.containsKey(today)) {
        attendanceHistory[today][kCheckOutTime] = Timestamp.fromDate(now);
        attendanceHistory[today][kCheckInLocation] = {
          kLatitude: officeLat,
          kLongitude: officeLong,
        };
        attendanceHistory[today][kTotalHours] = calculatedHours;
        attendanceHistory[today][kStatus] = kCompleted;
      }

      log('✅ Check-out recorded in memory');
      // _showSuccessDialog('Checked Out Successfully!');
    } else {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  Future<bool> _verifyLocation({
    required double allowedRadiusInMeters,
    required double officeLat,
    required double officeLong,
  }) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationStatus = 'Location services are disabled.'.tr();
        });
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            locationStatus = 'Location permission denied.'.tr();
          });
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationStatus = 'Location permission permanently denied.'.tr();
        });
        return false;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distanceInMeters = Geolocator.distanceBetween(
        officeLat,
        officeLong,
        position.latitude,
        position.longitude,
      );

      if (distanceInMeters <= allowedRadiusInMeters) {
        return true;
      } else {
        setState(() {
          locationStatus =
              'You are ${distanceInMeters.toStringAsFixed(0)}m away. Max allowed: ${allowedRadiusInMeters}m.';
        });
        return false;
      }
    } catch (e) {
      setState(() {
        locationStatus = 'Error verifying location: ${e.toString()}';
      });
      return false;
    }
  }

  DateTime _toMinutePrecision(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  String _calculateWorkedHours({DateTime? start, DateTime? end}) {
    DateTime? s = start ?? checkInTime;
    DateTime? e = end ?? checkOutTime;
    if (s == null || e == null) return '0h 0m';

    final cleanStart = _toMinutePrecision(s);
    final cleanEnd = _toMinutePrecision(e);

    Duration duration = cleanEnd.difference(cleanStart);
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);

    return '${hours}h ${minutes}m';
  }

  void _showSuccessDialog(String message) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: colorScheme.secondary, size: 32),
            const SizedBox(width: 12),
            Text(
              'Success'.tr(),
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}
