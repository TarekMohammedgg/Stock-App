import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/features/chatbot/presentation/views/chatbot_screen.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';
import 'package:gdrive_tutorial/services/insights_service.dart';
import 'package:intl/intl.dart';

class InsightsScreen extends StatefulWidget {
  static const String id = 'analytics_screen';
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final GSheetService _gSheetService = GSheetService();
  final InventoryIntelligenceService _intelligenceService =
      InventoryIntelligenceService();

  bool isLoading = true;
  List<Map<String, dynamic>> allSales = [];
  List<Map<String, dynamic>> filteredSales = [];

  // Date range state
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String selectedPeriod = 'Today';

  // Metrics
  Map<String, dynamic> topProduct = {};
  Map<String, dynamic> peakDay = {};
  Map<String, dynamic> peakTime = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      await _gSheetService.initialize();
      allSales = await _gSheetService.getSales();
      _selectPeriod('Today');
    } catch (e) {
      log('Error loading data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _selectPeriod(String period) {
    final now = DateTime.now();
    DateTime start = now;
    DateTime end = now;

    switch (period) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Year':
        start = DateTime(now.year, 1, 1);
        break;
    }

    setState(() {
      selectedPeriod = period;
      startDate = start;
      endDate = end;
      _calculateMetrics();
    });
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );

    if (picked != null) {
      setState(() {
        selectedPeriod = 'Custom';
        startDate = picked.start;
        endDate = picked.end;
        _calculateMetrics();
      });
    }
  }

  void _calculateMetrics() {
    filteredSales = _intelligenceService.filterSalesByDate(
      sales: allSales,
      startDate: startDate,
      endDate: endDate,
    );

    topProduct = _intelligenceService.getMostSoldItem(sales: filteredSales);
    peakDay = _intelligenceService.findMostSoldDay(sales: filteredSales);
    peakTime = _intelligenceService.findPeakSalesTime(sales: filteredSales);
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text('Stock Insights'.tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, ChatbotScreen.id),
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.auto_awesome),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPeriodSelector(colorScheme),
                    const SizedBox(height: 24),
                    _buildChartSection(colorScheme),
                    const SizedBox(height: 24),
                    _buildMetricCard(
                      title: 'Most Sold Product'.tr(),
                      value: topProduct['productName'] ?? 'N/A'.tr(),
                      subtitle:
                          topProduct['quantity'] != null &&
                              topProduct['quantity'] > 0
                          ? '${topProduct['quantity']} ${'units sold'.tr()}'
                          : 'No sales data'.tr(),
                      icon: Icons.inventory_2_outlined,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildMetricCard(
                      title: 'Most Sold Day'.tr(),
                      value: peakDay['date'] ?? 'N/A'.tr(),
                      subtitle:
                          peakDay['unitsSold'] != null &&
                              peakDay['unitsSold'] > 0
                          ? '${peakDay['unitsSold']} ${'units sold on this day'.tr()}'
                          : 'No sales data'.tr(),
                      icon: Icons.calendar_month_outlined,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildMetricCard(
                      title: 'Most Sold Time'.tr(),
                      value: peakTime['peakHourFormatted'] ?? 'N/A'.tr(),
                      subtitle:
                          peakTime['unitsSold'] != null &&
                              peakTime['unitsSold'] > 0
                          ? '${peakTime['unitsSold']} ${'units sold at this hour'.tr()}'
                          : 'No sales data'.tr(),
                      icon: Icons.access_time_outlined,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildChartSection(ColorScheme colorScheme) {
    // Process product sales for the chart using correct keys
    final Map<String, int> productSales = {};
    for (var sale in filteredSales) {
      final name = sale[kSaleProductName]?.toString() ?? 'Unknown';
      final qty = int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
      productSales[name] = (productSales[name] ?? 0) + qty;
    }

    // Sort and take top 5 for better visualization
    final sortedEntries = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(5).toList();

    if (topEntries.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(child: Text('No chart data available'.tr())),
      );
    }

    double maxQty = topEntries.first.value.toDouble();
    if (maxQty == 0) maxQty = 1;

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Performance'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.start,
                groupsSpace: 12,
                maxY: maxQty * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${topEntries[groupIndex].key}\n',
                        TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} units',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= topEntries.length) {
                          return const SizedBox();
                        }
                        final name = topEntries[index].key;
                        final displayName = name.length > 10
                            ? '${name.substring(0, 10)}...'
                            : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: RotatedBox(
                            quarterTurns: -1,
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 9,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                      reservedSize: 60,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(topEntries.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: topEntries[index].value.toDouble(),
                        color: colorScheme.primary,
                        width: 28,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxQty * 1.2,
                          color: colorScheme.primary.withOpacity(0.05),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sales Period'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),
            TextButton.icon(
              onPressed: _selectCustomRange,
              icon: const Icon(Icons.date_range),
              label: Text('Custom'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPeriodBtn('Today'.tr(), colorScheme),
            _buildPeriodBtn('Week'.tr(), colorScheme),
            _buildPeriodBtn('Month'.tr(), colorScheme),
            _buildPeriodBtn('Year'.tr(), colorScheme),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${DateFormat('MMM d, yyyy').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
          style: TextStyle(color: colorScheme.onBackground.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildPeriodBtn(String label, ColorScheme colorScheme) {
    bool isSelected = selectedPeriod == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _selectPeriod(label),
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
