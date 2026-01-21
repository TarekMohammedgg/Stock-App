import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // 1. إحداثيات مقر العمل (مثال: برج القاهرة)
  final double officeLat = 29.934596;
  final double officeLong = 31.264948;

  // 2. المسافة المسموح بها بالمتر (نصف القطر)
  final double allowedRadiusInMeters = 50.0;

  String message = "اضغط للتحقق من الحضور";

  Future<void> checkAttendance() async {
    bool serviceEnabled;
    LocationPermission permission;

    // أ. التأكد من أن خدمة الموقع مفعلة في الهاتف
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => message = "الرجاء تفعيل خدمة الموقع (GPS)");
      return;
    }

    // ب. طلب الصلاحيات من المستخدم
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => message = "تم رفض الصلاحية");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(
        () => message = "الصلاحية مرفوضة بشكل دائم، يرجى تغييرها من الإعدادات",
      );
      return;
    }

    // ج. الحصول على الموقع الحالي للموظف
    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high, // دقة عالية
    );

    // د. حساب المسافة بين الموظف والشركة (بالمتر)
    double distanceInMeters = Geolocator.distanceBetween(
      officeLat,
      officeLong,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    // هـ. الشرط (Condition)
    if (distanceInMeters <= allowedRadiusInMeters) {
      // الموظف داخل النطاق
      setState(() {
        message =
            "✅ تم تسجيل الحضور بنجاح! (المسافة: ${distanceInMeters.toStringAsFixed(1)} متر)";
      });
      // هنا يمكنك استدعاء API لتسجيل الحضور في قاعدة البيانات
    } else {
      // الموظف خارج النطاق
      setState(() {
        message =
            "❌ خطأ: أنت خارج نطاق العمل. (المسافة: ${distanceInMeters.toStringAsFixed(1)} متر)";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تسجيل الحضور")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: checkAttendance,
              child: Text("تسجيل حضور"),
            ),
          ],
        ),
      ),
    );
  }
}
