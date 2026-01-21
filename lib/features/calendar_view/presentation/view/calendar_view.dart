import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/helper.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarView extends StatefulWidget {
  static const String id = 'calendar_view';
  final List<Map<String, dynamic>>? allSales;

  const CalendarView({super.key, this.allSales});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final GSheetService gSheetService = GSheetService();
  List<Map<String, dynamic>>? allSales;
  List<Map<String, dynamic>> salesList = [];
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();
  CalendarFormat calendarFormat = CalendarFormat.month;
  bool isLoading = false;

  Future<void> getAllData() async {
    setState(() => isLoading = true);
    try {
      await gSheetService.initialize();
      allSales = await gSheetService.getSales();

      if (allSales != null) {
        _filterSalesForSelectedDay();
        log("Loaded ${salesList.length} sales for ${formatDate(selectedDay)}");
      }
    } catch (e) {
      log('Error loading sales: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Parse sale date from various formats (ISO 8601, Excel serial, etc.)
  DateTime? _parseSaleDate(dynamic saleDate) {
    if (saleDate == null) return null;

    try {
      // Try ISO 8601 format first (most common)
      if (saleDate is String && saleDate.contains('T')) {
        return DateTime.parse(saleDate);
      }

      // Try parsing as Excel serial number (numeric or string)
      final numericDate = saleDate is num
          ? saleDate.toDouble()
          : double.tryParse(saleDate.toString());

      if (numericDate != null) {
        // Convert Excel serial to DateTime
        final excelEpoch = DateTime(1899, 12, 30);
        return excelEpoch.add(Duration(days: numericDate.toInt()));
      }

      // Fallback: try parsing as any date string
      return DateTime.parse(saleDate.toString());
    } catch (e) {
      log('⚠️ Failed to parse date: $saleDate - $e');
      return null;
    }
  }

  void _filterSalesForSelectedDay() {
    if (allSales == null) return;

    log(
      '🔍 Filtering ${allSales!.length} sales for ${formatDate(selectedDay)}',
    );

    salesList = allSales!.where((sale) {
      final parsedDate = _parseSaleDate(sale[kSaleCreatedDate]);
      if (parsedDate == null) return false;

      final matches =
          parsedDate.year == selectedDay.year &&
          parsedDate.month == selectedDay.month &&
          parsedDate.day == selectedDay.day;

      if (matches) {
        log('✅ Match: ${sale[kSaleProductName]} on ${formatDate(parsedDate)}');
      }

      return matches;
    }).toList();

    log('✅ Found ${salesList.length} sales for ${formatDate(selectedDay)}');
  }

  int getSalesCountForDate(DateTime date) {
    if (allSales == null) return 0;

    return allSales!.where((sale) {
      final parsedDate = _parseSaleDate(sale[kSaleCreatedDate]);
      if (parsedDate == null) return false;

      return parsedDate.year == date.year &&
          parsedDate.month == date.month &&
          parsedDate.day == date.day;
    }).length;
  }

  @override
  void initState() {
    super.initState();

    // Use pre-loaded data if available, otherwise fetch
    if (widget.allSales != null) {
      allSales = widget.allSales;
      _filterSalesForSelectedDay();
      setState(() {});
    } else {
      getAllData();
    }
  }

  Map<int, String> map = {
    1: "Jan",
    12: "Dec",
    2: "Feb",
    3: "Mar",
    4: "Apr",
    5: "May",
    6: "Jun",
    7: "Jul",
    8: "Aug",
    9: "Sep",
    10: "Oct",
    11: "Nov",
  };

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        title: Text("Calendar View".tr()),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Modern Calendar Card
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: focusedDay,

                // KEY CONFIGURATION FOR THE LOOK IN YOUR IMAGE
                calendarFormat: calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.sunday,

                // Header Styling (The "December 2025" part)
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: colorScheme.onSurface,
                  ),
                  leftChevronIcon: Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  rightChevronIcon: Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),

                // Day Styling (The circles and text)
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                  todayDecoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  markerDecoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(color: colorScheme.onSurface),
                  weekendTextStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),

                // Logic for selecting dates
                selectedDayPredicate: (day) {
                  return isSameDay(selectedDay, day);
                },
                onDaySelected: (newSelectedDay, newFocusedDay) {
                  setState(() {
                    selectedDay = newSelectedDay;
                    focusedDay = newFocusedDay;
                    _filterSalesForSelectedDay();
                  });
                },
                eventLoader: (day) {
                  final count = getSalesCountForDate(day);
                  log("count: $count");
                  return List.generate(count > 3 ? 3 : count, (index) => '.');
                },
                onPageChanged: (newFocusedDay) {
                  focusedDay = newFocusedDay;
                },
              ),
            ),
            const SizedBox(height: 24),
            // Date Display Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 24,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEE, d MMM y').format(selectedDay),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Sales List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : salesList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No sales for this date".tr(),
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: salesList.length,
                      itemBuilder: (context, index) {
                        final sale = salesList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.shopping_cart_outlined,
                              size: 24,
                              color: colorScheme.primary,
                            ),
                            title: Text(
                              sale[kSaleProductName] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Quantity: ${sale[kSaleQuantity] ?? ''} • Price: \$${sale[kSaleProductPrice] ?? ''}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Sale'.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
