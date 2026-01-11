import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gdrive_tutorial/core/helper.dart';
import 'package:gdrive_tutorial/services/firestore_auth_service.dart';

import 'package:gdrive_tutorial/features/calendar_view/presentation/view/calendar_view.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/permission_helper.dart';
import 'package:gdrive_tutorial/features/insights/presentation/view/insight_screen.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/manager_employee_dashboard.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/allProducts.dart';
import 'package:gdrive_tutorial/features/employee/presentation/view/employee_screen.dart';

import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/product_dialog.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/quick_action.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/summary_card.dart';

import 'package:gdrive_tutorial/services/gsheet_service.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/logout_screen.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/credential_screen.dart';

class ManagerScreen extends StatefulWidget {
  static const String id = 'manager_screen';
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  final GSheetService gSheetService = GSheetService();

  bool isLoading = false;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> allSales = [];
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> activeEmployees = [];
  List<Map<String, dynamic>> latestSalesToday = [];

  double salesTodayValue = 0;
  double monthlyProfitValue = 0;
  int lowStockCount = 0;
  int todaySalesCount = 0;

  Timer? _refreshTimer;
  final FirestoreAuthService _authService = FirestoreAuthService();

  @override
  void initState() {
    super.initState();
    _checkCredentialsAndLoad();
    // Use a timer for periodic refresh instead of StreamBuilder in build()
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchData(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkCredentialsAndLoad() async {
    // Check if credentials exist in SharedPreferences
    final spreadsheetId = CacheHelper.getData(kSpreadsheetId) as String?;
    final folderId = CacheHelper.getData(kDriveFolderId) as String?;
    final appScriptUrl = CacheHelper.getData(kAppScriptUrl) as String?;

    // If any credential is missing or empty, navigate to credential screen
    if (spreadsheetId == null ||
        spreadsheetId.isEmpty ||
        folderId == null ||
        folderId.isEmpty ||
        appScriptUrl == null ||
        appScriptUrl.isEmpty) {
      log('⚠️ Manager credentials missing, navigating to credential screen');

      if (mounted) {
        final username = CacheHelper.getData(kUsername) ?? '';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CredentialScreen(username: username),
          ),
        );
      }
      return;
    }

    // Credentials exist, proceed with loading products
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    log('🔄 Starting to load dashboard data...');
    setState(() => isLoading = true);

    try {
      await gSheetService.initialize();
      await _fetchData();
    } catch (e) {
      log('❌ Error initializing data: $e');
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load data: $e');
    }
  }

  Future<void> _fetchData() async {
    try {
      log('� Refreshing dashboard data...');
      final managerEmail = CacheHelper.getData(kEmail);
      if (managerEmail == null) return;

      // Parallel fetch for better performance
      final results = await Future.wait([
        gSheetService.getProducts(),
        gSheetService.getSales(),
        _authService.getEmployees(managerEmail),
      ]);

      final loadedProducts = results[0];
      final loadedSales = results[1];
      final loadedEmployees = results[2];

      _calculateStats(loadedProducts, loadedSales, loadedEmployees);

      setState(() {
        products = loadedProducts;
        allSales = loadedSales;
        employees = loadedEmployees;
        isLoading = false;
      });

      log(
        '✅ Dashboard refreshed. Sales: ${allSales.length}, Active: ${activeEmployees.length}',
      );
    } catch (e) {
      log('❌ Auto-refresh error: $e');
    }
  }

  void _calculateStats(
    List<Map<String, dynamic>> loadedProducts,
    List<Map<String, dynamic>> loadedSales,
    List<Map<String, dynamic>> loadedEmployees,
  ) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    double todayTotal = 0;
    double monthTotal = 0;
    int todayCount = 0;
    List<Map<String, dynamic>> salesToday = [];

    // Process Sales
    for (var sale in loadedSales) {
      final saleDateRaw = sale[kSaleCreatedDate]?.toString() ?? '';
      if (saleDateRaw.isEmpty) continue;

      DateTime? saleDate;
      try {
        // First, try parsing as ISO8601 string
        saleDate = DateTime.tryParse(saleDateRaw);

        if (saleDate == null) {
          // Check if it's an Excel/Google Sheets serial number (e.g., 46030.74)
          final serialNumber = double.tryParse(saleDateRaw);
          if (serialNumber != null && serialNumber > 25000) {
            // Excel epoch is December 30, 1899
            final excelEpoch = DateTime(1899, 12, 30);
            saleDate = excelEpoch.add(
              Duration(
                days: serialNumber.floor(),
                milliseconds: ((serialNumber % 1) * 86400000).round(),
              ),
            );
          }
        }

        if (saleDate == null) {
          // Try manual parsing for "M/d/yyyy" format
          final parts = saleDateRaw.split(' ')[0].split('/');
          if (parts.length == 3) {
            int m = int.parse(parts[0]);
            int d = int.parse(parts[1]);
            int y = int.parse(parts[2]);
            saleDate = DateTime(y, m, d);
          }
        }
      } catch (_) {
        // Parsing failed
      }

      final price =
          double.tryParse(sale[kSaleProductPrice]?.toString() ?? '0') ?? 0;
      final qty = double.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
      final total = price * qty;

      bool isToday = false;
      bool isThisMonth = false;

      if (saleDate != null) {
        isToday =
            saleDate.year == now.year &&
            saleDate.month == now.month &&
            saleDate.day == now.day;
        isThisMonth = saleDate.year == now.year && saleDate.month == now.month;
      }

      if (isToday) {
        todayTotal += total;
        todayCount++;
        salesToday.add(sale);
      }

      if (isThisMonth) {
        monthTotal += total;
      }
    }

    // Sort today's sales by newest first (assuming sale ID or format allows sorting)
    salesToday.sort(
      (a, b) => (b[kSaleCreatedDate]?.toString() ?? '').compareTo(
        a[kSaleCreatedDate]?.toString() ?? '',
      ),
    );

    // Process Low Stock
    int lowCount = loadedProducts.where((p) {
      final name = p[kProductName]?.toString() ?? '';
      if (name.isEmpty) return false; // Ignore empty/header rows

      final qty = int.tryParse(p[kProductQuantity]?.toString() ?? '0') ?? 0;
      return qty <= kLowStockThreshold;
    }).length;

    // Process Active Employees
    List<Map<String, dynamic>> activeEmps = [];
    for (var emp in loadedEmployees) {
      final attendance = emp[kAttendance] as Map<String, dynamic>?;
      if (attendance != null && attendance.containsKey(todayStr)) {
        final todayData = attendance[todayStr] as Map<String, dynamic>;
        final hasCheckIn = todayData[kCheckInTime] != null;
        final hasCheckOut = todayData[kCheckOutTime] != null;

        if (hasCheckIn && !hasCheckOut) {
          activeEmps.add(emp);
        }
      }
    }

    setState(() {
      salesTodayValue = todayTotal;
      monthlyProfitValue = monthTotal;
      todaySalesCount = todayCount;
      lowStockCount = lowCount;
      latestSalesToday = salesToday.take(5).toList();
      activeEmployees = activeEmps;
    });
  }

  Future<void> withoutInsertData() async {
    await gSheetService.initialize();
  }

  void _showAddProductDialog() async {
    // Check permission first
    final hasPermission = await PermissionHelper.canAddProduct();
    if (!hasPermission) {
      _showErrorSnackBar('You do not have permission to add products'.tr());
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ProductDialog(onSave: () => _loadProducts()),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  final helloUsername = capitalize(CacheHelper.getData(kUsername));

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    final managerEmail = CacheHelper.getData(kEmail);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LogoutScreen(),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: colorScheme.primary, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hi'.tr(namedArgs: {'name': helloUsername}),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      managerEmail ?? "manager@stock.com",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onBackground.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManagerEmployeeDashboard(),
                ),
              );
            },
            icon: Icon(Icons.people, color: colorScheme.primary),
            tooltip: 'Employee Management'.tr(),
          ),
          IconButton(
            onPressed: () async {
              await withoutInsertData();
              SystemChannels.textInput.invokeMethod('TextInput.hide');

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final allSales = await gSheetService.getSales();
                if (mounted) Navigator.pop(context);

                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CalendarView(allSales: allSales),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
                _showErrorSnackBar('Failed to load calendar data'.tr());
              }
            },
            icon: Icon(Icons.calendar_month, color: colorScheme.primary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: CustomScrollView(
          slivers: [
            // 1. The Grid Section
            SliverGrid.count(
              crossAxisCount: 2,
              children: [
                SummaryCard(
                  title: "Total Products".tr(),
                  value: NumberFormat.decimalPattern(
                    'en_US',
                  ).format(products.length),
                  icon: Icons.inventory,
                  isLoading: isLoading,
                  onTap: () => Navigator.pushNamed(context, AllProducts.id),
                ),
                SummaryCard(
                  title: "Sales Today".tr(),
                  value:
                      "\$${NumberFormat.decimalPattern('en_US').format(salesTodayValue)}",
                  subValue: "$todaySalesCount ${'sales'.tr()}",
                  icon: Icons.attach_money,
                  isLoading: isLoading,
                ),
                SummaryCard(
                  title: "Low Stock".tr(),
                  value: lowStockCount.toString(),
                  icon: Icons.warning,
                  isLoading: isLoading,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AllProducts.id,
                    arguments: {'filterLowStock': true},
                  ),
                ),
                SummaryCard(
                  title: "Monthly Profit".tr(),
                  value:
                      "\$${NumberFormat.decimalPattern('en_US').format(monthlyProfitValue)}",
                  icon: Icons.trending_up,
                  isLoading: isLoading,
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(
                          "Quick Actions".tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      QuickActionButton(
                        icon: Icons.add,
                        label: "Add Product".tr(),
                        onTap: _showAddProductDialog,
                      ),
                      QuickActionButton(
                        icon: Icons.analytics,
                        label: "Insights".tr(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InsightsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  // Add some spacing before the list starts
                  const SizedBox(height: 10),

                  _buildSectionHeader(
                    context,
                    "Last Sales Transactions Today".tr(),
                    Icons.receipt_long,
                  ),
                  _buildLastTransactions(context),

                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    "Employees Attendance Today".tr(),
                    Icons.people,
                  ),
                  _buildActiveEmployees(context),

                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmployeeScreen()),
          );
        },
        icon: Icon(Icons.shopping_cart, color: colorScheme.onPrimary),
        label: Text(
          'Add Transaction'.tr(),
          style: TextStyle(color: colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastTransactions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (latestSalesToday.isEmpty) {
      return _buildEmptyListPlaceholder(context, "No transactions today".tr());
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: latestSalesToday.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.05)),
        itemBuilder: (context, index) {
          final sale = latestSalesToday[index];
          final saleDateRaw = sale[kSaleCreatedDate]?.toString() ?? '';
          String time = '--:--';

          if (saleDateRaw.isNotEmpty) {
            try {
              DateTime? dt = DateTime.tryParse(saleDateRaw);

              // Handle Excel serial number format
              if (dt == null) {
                final serialNumber = double.tryParse(saleDateRaw);
                if (serialNumber != null && serialNumber > 25000) {
                  final excelEpoch = DateTime(1899, 12, 30);
                  dt = excelEpoch.add(
                    Duration(
                      days: serialNumber.floor(),
                      milliseconds: ((serialNumber % 1) * 86400000).round(),
                    ),
                  );
                }
              }

              if (dt != null) {
                time = DateFormat('hh:mm a').format(dt);
              }
            } catch (_) {}
          }
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.shopping_cart,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            title: Text(
              sale[kSaleProductName] ?? 'Unknown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              "at $time • Qty: ${sale[kSaleQuantity]}",
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            ),
            trailing: Text(
              "\$${sale[kSaleProductPrice]}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveEmployees(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (employees.isEmpty) {
      return _buildEmptyListPlaceholder(context, "No employees found".tr());
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final emp = employees[index];

          // Determine attendance status
          String status = 'Not yet';
          Color statusColor = Colors.grey;
          IconData statusIcon = Icons.schedule;

          final attendance = emp[kAttendance] as Map<String, dynamic>?;
          if (attendance != null && attendance.containsKey(todayStr)) {
            final todayData = attendance[todayStr] as Map<String, dynamic>;
            final hasCheckIn = todayData[kCheckInTime] != null;
            final hasCheckOut = todayData[kCheckOutTime] != null;

            if (hasCheckIn && !hasCheckOut) {
              status = 'Checked In';
              statusColor = colorScheme.secondary;
              statusIcon = Icons.login;
            } else if (hasCheckIn && hasCheckOut) {
              status = 'Checked Out';
              statusColor = Colors.orange;
              statusIcon = Icons.logout;
            }
          }

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)),
            ),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Text(
                      (emp[kEmployeeDisplayName] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(statusIcon, size: 8, color: Colors.white),
                    ),
                  ),
                ],
              ),
              title: Text(
                emp[kEmployeeDisplayName] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                emp[kEmployeeUsername] ?? '',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyListPlaceholder(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 24,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
