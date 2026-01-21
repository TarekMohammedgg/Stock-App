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
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/manager_transaction_screen.dart';

import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/product_dialog.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/quick_action.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/summary_card.dart';

import 'package:gdrive_tutorial/services/gsheet_service.dart';
import 'package:gdrive_tutorial/features/authentication/presentation/views/logout_screen.dart';
import 'package:gdrive_tutorial/core/shared_prefs.dart';
import 'package:gdrive_tutorial/features/manager/presentation/view/widgets/credential_screen.dart';

// Invoice imports
import 'package:gdrive_tutorial/features/invoice/data/api/pdf_api.dart';
import 'package:gdrive_tutorial/features/invoice/data/api/pdf_invoice_api.dart';
import 'package:gdrive_tutorial/features/invoice/data/model/invoice.dart';
import 'package:gdrive_tutorial/features/invoice/data/model/customer.dart';
import 'package:gdrive_tutorial/features/invoice/data/model/supplier.dart';

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
  List<Map<String, dynamic>> productItems = []; // Product batches
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
    _checkStatusAndCredentials();
    // Use a timer for periodic refresh instead of StreamBuilder in build()
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isManagerActive) {
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool _isManagerActive = true; // Default to true for backward compatibility

  Future<void> _checkStatusAndCredentials() async {
    // Check if manager is active
    final isActive = CacheHelper.getData(kPrefManagerIsActive);

    // If explicitly false, set to inactive. If null, assume true (for legacy)
    if (isActive == false) {
      if (mounted) {
        setState(() {
          _isManagerActive = false;
          isLoading = false;
        });
      }
      return;
    }

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
      log('🔄 Refreshing dashboard data...');
      final managerEmail = CacheHelper.getData(kEmail);
      if (managerEmail == null) return;

      // Parallel fetch for better performance
      final results = await Future.wait([
        gSheetService.getProducts(),
        gSheetService.getProductItems(), // Fetch product batches
        gSheetService.getSales(),
        _authService.getEmployees(managerEmail),
      ]);

      final loadedProducts = results[0];
      final loadedProductItems = results[1]; // Product batches
      final loadedSales = results[2];
      final loadedEmployees = results[3];

      _calculateStats(
        loadedProducts,
        loadedProductItems,
        loadedSales,
        loadedEmployees,
      );

      setState(() {
        products = loadedProducts;
        productItems = loadedProductItems;
        allSales = loadedSales;
        employees = loadedEmployees;
        isLoading = false;
      });

      log(
        '✅ Dashboard refreshed. Products: ${products.length}, ProductItems: ${productItems.length}',
      );
    } catch (e) {
      log('❌ Auto-refresh error: $e');
    }
  }

  void _calculateStats(
    List<Map<String, dynamic>> loadedProducts,
    List<Map<String, dynamic>> loadedProductItems,
    List<Map<String, dynamic>> loadedSales,
    List<Map<String, dynamic>> loadedEmployees,
  ) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    double todayTotal = 0;
    double monthTotal = 0;
    int todayCount = 0;
    List<Map<String, dynamic>> salesToday = [];

    // Process Sales - using new structure with kSalesTotalPrice
    for (var sale in loadedSales) {
      // Try new field first, fallback to legacy field
      final saleDateRaw =
          sale[kSalesCreatedDate]?.toString() ??
          sale[kSaleCreatedDate]?.toString() ??
          '';
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

      // Use kSalesTotalPrice from new structure, fallback to calculated price*qty for legacy
      double total = 0;
      if (sale[kSalesTotalPrice] != null) {
        // New structure: use total price directly
        total = double.tryParse(sale[kSalesTotalPrice]?.toString() ?? '0') ?? 0;
      } else {
        // Legacy structure: calculate price * qty
        final price =
            double.tryParse(sale[kSaleProductPrice]?.toString() ?? '0') ?? 0;
        final qty =
            double.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
        total = price * qty;
      }

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

    // Calculate total quantities per product from ProductItems
    // Group ProductItems by productId and sum quantities
    Map<String, int> productQuantities = {};
    for (var item in loadedProductItems) {
      final productId = item[kProductItemProductId]?.toString() ?? '';
      if (productId.isEmpty) continue;

      final qty =
          int.tryParse(item[kProductItemQuantity]?.toString() ?? '0') ?? 0;
      productQuantities[productId] = (productQuantities[productId] ?? 0) + qty;
    }

    // Count products with low stock (total quantity <= kLowStockThreshold)
    int lowCount = 0;
    for (var product in loadedProducts) {
      final productId = product[kProductId]?.toString() ?? '';
      final name = product[kProductName]?.toString() ?? '';
      if (name.isEmpty || productId.isEmpty) {
        continue; // Ignore empty/header rows
      }

      final totalQty = productQuantities[productId] ?? 0;
      if (totalQty <= kLowStockThreshold) {
        lowCount++;
      }
    }

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

  /// Generate PDF invoice for a sale transaction
  Future<void> _generateInvoice(Map<String, dynamic> sale) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final saleId =
          sale[kSalesId]?.toString() ?? sale[kSaleId]?.toString() ?? '';
      final createdDateRaw =
          sale[kSalesCreatedDate]?.toString() ??
          sale[kSaleCreatedDate]?.toString() ??
          '';
      final employeeUsername =
          sale[kSalesEmployeeUsername]?.toString() ?? 'Unknown'.tr();

      // Parse sale date
      DateTime saleDate = DateTime.now();
      if (createdDateRaw.isNotEmpty) {
        saleDate = DateTime.tryParse(createdDateRaw) ?? DateTime.now();
      }

      // Fetch sale items for this sale
      final saleItems = await gSheetService.getSalesItemsBySaleId(saleId);

      // Build invoice items from sale items
      List<InvoiceItem> invoiceItems = [];

      if (saleItems.isNotEmpty) {
        for (var item in saleItems) {
          final productId = item[kSalesItemProductId]?.toString() ?? '';
          final quantity =
              int.tryParse(item[kSalesItemQuantity]?.toString() ?? '0') ?? 0;
          final price =
              double.tryParse(item[kSalesItemPrice]?.toString() ?? '0') ?? 0;

          // Find product name
          String productName = 'Product #$productId';
          final product = products.firstWhere(
            (p) => p[kProductId]?.toString() == productId,
            orElse: () => {},
          );
          if (product.isNotEmpty) {
            productName = product[kProductName]?.toString() ?? productName;
          }

          invoiceItems.add(
            InvoiceItem(
              description: productName,
              date: saleDate,
              quantity: quantity,
              unitPrice: price,
            ),
          );
        }
      } else {
        // Legacy structure - single item sale
        final productName = sale[kSaleProductName]?.toString() ?? 'Product';
        final quantity =
            int.tryParse(sale[kSaleQuantity]?.toString() ?? '1') ?? 1;
        final price =
            double.tryParse(sale[kSaleProductPrice]?.toString() ?? '0') ?? 0;

        invoiceItems.add(
          InvoiceItem(
            description: productName,
            date: saleDate,
            quantity: quantity,
            unitPrice: price,
          ),
        );
      }

      // Get manager info for supplier
      final managerEmail = CacheHelper.getData(kEmail) ?? 'store@example.com';
      final managerName = CacheHelper.getData(kDisplayName) ?? 'Store Manager';

      // Create invoice (always in English)
      final invoice = Invoice(
        info: InvoiceInfo(
          description: 'Sale Transaction #$saleId',
          number: saleId,
          date: saleDate,
          dueDate: saleDate.add(const Duration(days: 7)),
        ),
        supplier: Supplier(
          name: managerName,
          address: managerEmail,
          paymentInfo: managerEmail,
        ),
        customer: Customer(
          name: 'Walk-in Customer',
          address: 'Served by: $employeeUsername',
        ),
        items: invoiceItems,
      );

      // Generate and open PDF (always English)
      final pdfFile = await PdfInvoiceApi.generate(invoice);

      if (mounted) Navigator.pop(context); // Dismiss loading

      await PdfApi.openFile(pdfFile);
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading
      log('Error generating invoice: $e');
      _showErrorSnackBar('Failed to generate invoice'.tr());
    }
  }

  final helloUsername = capitalize(CacheHelper.getData(kUsername));

  @override
  Widget build(BuildContext context) {
    if (!_isManagerActive) {
      return _buildPendingActivationView();
    }

    ColorScheme colorScheme = Theme.of(context).colorScheme;
    final managerEmail = CacheHelper.getData(kEmail);

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                      color: colorScheme.onSurface,
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
                        color: colorScheme.onSurface.withOpacity(0.6),
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
                            color: colorScheme.onSurface,
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
            MaterialPageRoute(
              builder: (context) => const ManagerTransactionScreen(),
            ),
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
              color: colorScheme.onSurface,
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

          // Try new field first, fallback to legacy
          final saleDateRaw =
              sale[kSalesCreatedDate]?.toString() ??
              sale[kSaleCreatedDate]?.toString() ??
              '';
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

          // Get display values - support both new and legacy structure
          final String totalPrice =
              sale[kSalesTotalPrice]?.toString() ??
              sale[kSaleProductPrice]?.toString() ??
              '0';
          final String saleId =
              sale[kSalesId]?.toString() ?? sale[kSaleId]?.toString() ?? '';

          // For new structure, show employee name. For legacy, show product name
          final bool isNewStructure = sale[kSalesTotalPrice] != null;

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.receipt_long,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            title: Text(
              isNewStructure
                  ? '${'Invoice'.tr()}#$saleId'
                  : (sale[kSaleProductName]?.toString() ?? 'Unknown'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              isNewStructure
                  ? "at $time • by ${sale[kSalesEmployeeUsername] ?? 'Unknown'}"
                  : "at $time • Qty: ${sale[kSaleQuantity] ?? '-'}",
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "\$$totalPrice",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.picture_as_pdf,
                    color: colorScheme.secondary,
                    size: 20,
                  ),
                  tooltip: 'Generate Invoice'.tr(),
                  onPressed: () => _generateInvoice(sale),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
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

  Widget _buildPendingActivationView() {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Account Status'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, LogoutScreen.id);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_empty_rounded,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Activation Pending'.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your account is currently inactive.\nPlease wait for the administrator to activate your account.'
                    .tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    setState(() => isLoading = true);
                    // Reload user data to check if active
                    final username = CacheHelper.getData(kUsername);
                    if (username != null) {
                      final userData = await _authService.getUserData(
                        username,
                        kUserTypeManager,
                      );
                      if (userData != null) {
                        final isActive = userData[kEmployeeIsActive] ?? false;
                        await CacheHelper.saveData(
                          kPrefManagerIsActive,
                          isActive,
                        );

                        if (isActive && mounted) {
                          setState(() => _isManagerActive = true);
                          _loadProducts();
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Account is still inactive'.tr()),
                              ),
                            );
                          }
                        }
                      }
                    }
                    if (mounted) setState(() => isLoading = false);
                  },
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    isLoading ? 'Checking...'.tr() : 'Check Status'.tr(),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } // Added closing brace for class logic if needed, wait, this is inside class, so just a method.
}
