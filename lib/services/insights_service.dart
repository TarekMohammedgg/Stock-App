import 'dart:developer';
import 'package:gdrive_tutorial/core/consts.dart';

/// Enterprise Inventory Intelligence Service
/// Provides advanced analytics and actionable insights for inventory management
class InventoryIntelligenceService {
  /// Calculate GMROI (Gross Margin Return on Investment)
  /// Formula: Gross Margin ÷ Average Inventory Cost
  /// Returns: Dollar return for every $1 invested in inventory
  double calculateGMROI({
    required List<Map<String, dynamic>> sales,
    required List<Map<String, dynamic>> products,
  }) {
    try {
      // Calculate total revenue and COGS
      double totalRevenue = 0;
      double totalCOGS = 0;

      for (final sale in sales) {
        final price =
            double.tryParse(sale[kSaleProductPrice]?.toString() ?? '0') ?? 0;
        final qty = int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
        final revenue = price * qty;
        totalRevenue += revenue;

        // Estimate COGS at 60% of selling price (can be made configurable)
        totalCOGS += revenue * 0.6;
      }

      final grossMargin = totalRevenue - totalCOGS;

      // Calculate average inventory cost
      double totalInventoryValue = 0;
      for (final product in products) {
        final price =
            double.tryParse(product[kProductPrice]?.toString() ?? '0') ?? 0;
        final qty =
            int.tryParse(product[kProductQuantity]?.toString() ?? '0') ?? 0;
        // Estimate cost at 60% of selling price
        totalInventoryValue += (price * 0.6) * qty;
      }

      if (totalInventoryValue == 0) return 0;

      final gmroi = grossMargin / totalInventoryValue;
      log(
        '📊 GMROI: $gmroi (Margin: \$${grossMargin.toStringAsFixed(2)}, Inventory: \$${totalInventoryValue.toStringAsFixed(2)})',
      );

      return gmroi;
    } catch (e) {
      log('Error calculating GMROI: $e');
      return 0;
    }
  }

  /// Calculate Inventory Turnover Ratio
  /// Formula: COGS ÷ Average Inventory Value
  double calculateTurnoverRatio({
    required List<Map<String, dynamic>> sales,
    required List<Map<String, dynamic>> products,
  }) {
    try {
      // Calculate COGS
      double totalCOGS = 0;
      for (final sale in sales) {
        final price =
            double.tryParse(sale[kSaleProductPrice]?.toString() ?? '0') ?? 0;
        final qty = int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
        totalCOGS += (price * 0.6) * qty; // Estimate COGS
      }

      // Calculate average inventory value
      double totalInventoryValue = 0;
      for (final product in products) {
        final price =
            double.tryParse(product[kProductPrice]?.toString() ?? '0') ?? 0;
        final qty =
            int.tryParse(product[kProductQuantity]?.toString() ?? '0') ?? 0;
        totalInventoryValue += (price * 0.6) * qty;
      }

      if (totalInventoryValue == 0) return 0;

      return totalCOGS / totalInventoryValue;
    } catch (e) {
      log('Error calculating turnover ratio: $e');
      return 0;
    }
  }

  /// Calculate Days Sales of Inventory (DSI)
  /// Formula: 365 ÷ Turnover Ratio
  int calculateDSI(double turnoverRatio) {
    if (turnoverRatio == 0) return 0;
    return (365 / turnoverRatio).round();
  }

  /// Calculate total cash tied up in inventory
  double calculateCashTiedUp(List<Map<String, dynamic>> products) {
    double total = 0;
    for (final product in products) {
      final price =
          double.tryParse(product[kProductPrice]?.toString() ?? '0') ?? 0;
      final qty =
          int.tryParse(product[kProductQuantity]?.toString() ?? '0') ?? 0;
      total += (price * 0.6) * qty; // Cost price estimate
    }
    return total;
  }

  /// Calculate risk score based on inventory health
  /// Returns: Risk score (higher = more risk)
  Map<String, dynamic> calculateRiskScore({
    required List<Map<String, dynamic>> products,
    required List<Map<String, dynamic>> sales,
  }) {
    int stockOutRisk = 0;
    int obsoleteRisk = 0;

    // Count products at risk

    // Count products at risk
    for (final product in products) {
      final qty =
          int.tryParse(product[kProductQuantity]?.toString() ?? '0') ?? 0;

      // Stock-out risk (< 5 units)
      if (qty < 5 && qty > 0) {
        stockOutRisk++;
      }

      // Check if product has recent sales
      final productId = product[kProductId]?.toString() ?? '';
      final recentSales = sales.where((sale) {
        return sale[kSaleProductId]?.toString() == productId;
      }).toList();

      // Obsolete risk (no sales and has stock)
      if (recentSales.isEmpty && qty > 0) {
        obsoleteRisk++;
      }
    }

    final totalRisk = (stockOutRisk * 2) + (obsoleteRisk * 1);

    return {
      'totalScore': totalRisk,
      'stockOutCount': stockOutRisk,
      'obsoleteCount': obsoleteRisk,
      'expiringCount': 0, // Placeholder - needs expiry date data
    };
  }

  /// Classify products into Stars, Dogs, Workhorses, Question Marks
  Map<String, List<Map<String, dynamic>>> classifyProducts({
    required List<Map<String, dynamic>> products,
    required List<Map<String, dynamic>> sales,
  }) {
    final Map<String, List<Map<String, dynamic>>> classification = {
      'stars': [],
      'dogs': [],
      'workhorses': [],
      'questionMarks': [],
    };

    for (final product in products) {
      final productId = product[kProductId]?.toString() ?? '';

      // Calculate sales velocity
      final productSales = sales.where((sale) {
        return sale[kSaleProductId]?.toString() == productId;
      }).toList();

      final totalQtySold = productSales.fold<int>(0, (sum, sale) {
        return sum +
            (int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0);
      });

      // Estimate margin (40% of selling price)
      final marginPercent = 40.0;

      // Classification logic
      final isHighVolume = totalQtySold >= 10;
      final isHighMargin = marginPercent >= 30;

      if (isHighVolume && isHighMargin) {
        classification['stars']!.add(product);
      } else if (!isHighVolume && !isHighMargin) {
        classification['dogs']!.add(product);
      } else if (isHighVolume && !isHighMargin) {
        classification['workhorses']!.add(product);
      } else {
        classification['questionMarks']!.add(product);
      }
    }

    return classification;
  }

  /// Calculate shrinkage (system vs physical variance)
  /// Note: Requires physical count data
  Map<String, dynamic> calculateShrinkage(List<Map<String, dynamic>> products) {
    // Placeholder - requires physical count data
    // For now, simulate 2% shrinkage
    final totalItems = products.fold<int>(0, (sum, product) {
      return sum +
          (int.tryParse(product[kProductQuantity]?.toString() ?? '0') ?? 0);
    });

    final estimatedShrinkage = (totalItems * 0.02).round();
    final shrinkageRate = 2.0;

    return {
      'shrinkageRate': shrinkageRate,
      'itemsAffected': estimatedShrinkage,
      'estimatedLoss': estimatedShrinkage * 10.0, // Estimate $10 per item
      'status': shrinkageRate < 2
          ? 'healthy'
          : (shrinkageRate < 5 ? 'warning' : 'critical'),
    };
  }

  /// Perform Pareto Analysis (80/20 rule)
  Map<String, List<Map<String, dynamic>>> performParetoAnalysis({
    required List<Map<String, dynamic>> products,
    required List<Map<String, dynamic>> sales,
  }) {
    // Calculate revenue per product
    final Map<String, double> productRevenue = {};

    for (final sale in sales) {
      final productId = sale[kSaleProductId]?.toString() ?? '';
      final price =
          double.tryParse(sale[kSaleProductPrice]?.toString() ?? '0') ?? 0;
      final qty = int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
      final revenue = price * qty;

      productRevenue[productId] = (productRevenue[productId] ?? 0) + revenue;
    }

    // Sort by revenue
    final sortedProducts = products.toList()
      ..sort((a, b) {
        final aRevenue = productRevenue[a[kProductId]?.toString() ?? ''] ?? 0;
        final bRevenue = productRevenue[b[kProductId]?.toString() ?? ''] ?? 0;
        return bRevenue.compareTo(aRevenue);
      });

    // Calculate cumulative revenue
    final totalRevenue = productRevenue.values.fold<double>(
      0,
      (sum, rev) => sum + rev,
    );
    double cumulativeRevenue = 0;

    final Map<String, List<Map<String, dynamic>>> classification = {
      'classA': [], // Top 20% → 80% revenue
      'classB': [], // Next 30% → 15% revenue
      'classC': [], // Bottom 50% → 5% revenue
    };

    for (int i = 0; i < sortedProducts.length; i++) {
      final product = sortedProducts[i];
      final productId = product[kProductId]?.toString() ?? '';
      final revenue = productRevenue[productId] ?? 0;
      cumulativeRevenue += revenue;

      final cumulativePercent = (cumulativeRevenue / totalRevenue) * 100;

      if (cumulativePercent <= 80) {
        classification['classA']!.add(product);
      } else if (cumulativePercent <= 95) {
        classification['classB']!.add(product);
      } else {
        classification['classC']!.add(product);
      }
    }

    return classification;
  }

  /// Calculate sell-through rate by category
  Map<String, double> calculateSellThroughRate({
    required List<Map<String, dynamic>> products,
    required List<Map<String, dynamic>> sales,
  }) {
    // Group by category (using product name prefix as category for now)
    final Map<String, Map<String, int>> categoryData = {};

    for (final product in products) {
      final name = product[kProductName]?.toString() ?? 'Unknown';
      final category = name.split(' ').first; // Simple categorization
      final qty =
          int.tryParse(product[kProductQuantity]?.toString() ?? '0') ?? 0;

      if (!categoryData.containsKey(category)) {
        categoryData[category] = {'received': 0, 'sold': 0};
      }

      categoryData[category]!['received'] =
          (categoryData[category]!['received'] ?? 0) + qty;
    }

    // Add sold quantities
    for (final sale in sales) {
      final name = sale[kSaleProductName]?.toString() ?? 'Unknown';
      final category = name.split(' ').first;
      final qty = int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;

      if (categoryData.containsKey(category)) {
        categoryData[category]!['sold'] =
            (categoryData[category]!['sold'] ?? 0) + qty;
      }
    }

    // Calculate rates
    final Map<String, double> sellThroughRates = {};
    categoryData.forEach((category, data) {
      final received = data['received'] ?? 0;
      final sold = data['sold'] ?? 0;
      final total = received + sold;

      if (total > 0) {
        sellThroughRates[category] = (sold / total) * 100;
      }
    });

    return sellThroughRates;
  }

  /// Get health status based on metric value
  String getHealthStatus(
    double value,
    double greenThreshold,
    double amberThreshold,
  ) {
    if (value >= greenThreshold) return 'healthy';
    if (value >= amberThreshold) return 'warning';
    return 'critical';
  }

  /// Get color for health status
  String getStatusColor(String status) {
    switch (status) {
      case 'healthy':
        return '0xFF10B981'; // Green
      case 'warning':
        return '0xFFF59E0B'; // Amber
      case 'critical':
        return '0xFFEF4444'; // Red
      default:
        return '0xFF6B7280'; // Gray
    }
  }

  // ==================== CALENDAR-BASED ANALYTICS ====================

  /// Parse sale date from various formats
  DateTime? _parseSaleDate(dynamic saleDate) {
    if (saleDate == null) return null;

    try {
      // Try parsing as numeric Excel serial number
      final numericDate = saleDate is num
          ? saleDate.toDouble()
          : double.tryParse(saleDate.toString());

      if (numericDate != null) {
        // Excel's epoch is Dec 30, 1899.
        // Serial numbers are essentially "days since epoch".
        final excelEpoch = DateTime(1899, 12, 30);
        // We handle decimals as well (time of day)
        return excelEpoch.add(
          Duration(milliseconds: (numericDate * 24 * 60 * 60 * 1000).round()),
        );
      }

      // Try ISO 8601 or common formats
      return DateTime.tryParse(saleDate.toString());
    } catch (e) {
      log('⚠️ Failed to parse date: $saleDate - $e');
      return null;
    }
  }

  /// Filter sales by date range
  List<Map<String, dynamic>> filterSalesByDate({
    required List<Map<String, dynamic>> sales,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Normalize dates to start/end of day
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    return sales.where((sale) {
      final saleDate = _parseSaleDate(sale[kSaleCreatedDate]);
      if (saleDate == null) return false;
      return saleDate.isAfter(
            normalizedStart.subtract(const Duration(seconds: 1)),
          ) &&
          saleDate.isBefore(normalizedEnd.add(const Duration(seconds: 1)));
    }).toList();
  }

  /// Calculate total revenue for a list of sales
  double calculateTotalRevenue({required List<Map<String, dynamic>> sales}) {
    double total = 0;
    for (final sale in sales) {
      final price =
          double.tryParse(sale[kSaleProductPrice]?.toString() ?? '0') ?? 0;
      final qty = int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
      total += price * qty;
    }
    return total;
  }

  /// Find peak sales time (hour of day with most units sold)
  Map<String, dynamic> findPeakSalesTime({
    required List<Map<String, dynamic>> sales,
  }) {
    if (sales.isEmpty) {
      return {'peakHour': -1, 'peakHourFormatted': 'No data', 'unitsSold': 0};
    }

    final Map<int, int> unitsByHour = {};

    for (final sale in sales) {
      final saleDate = _parseSaleDate(sale[kSaleCreatedDate]);
      if (saleDate == null) continue;

      final hour = saleDate.hour;
      final qty = int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
      unitsByHour[hour] = (unitsByHour[hour] ?? 0) + qty;
    }

    if (unitsByHour.isEmpty) {
      return {'peakHour': -1, 'peakHourFormatted': 'No data', 'unitsSold': 0};
    }

    final peakEntry = unitsByHour.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final hour = peakEntry.key;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return {
      'peakHour': hour,
      'peakHourFormatted': '$hour12:00 $period',
      'unitsSold': peakEntry.value,
    };
  }

  /// Get most sold item (by quantity)
  Map<String, dynamic> getMostSoldItem({
    required List<Map<String, dynamic>> sales,
  }) {
    if (sales.isEmpty) {
      return {'productName': 'No sales', 'quantity': 0};
    }

    final Map<String, int> productQty = {};

    for (final sale in sales) {
      final name = sale[kSaleProductName]?.toString() ?? 'Unknown';
      final qty = int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
      productQty[name] = (productQty[name] ?? 0) + qty;
    }

    if (productQty.isEmpty) return {'productName': 'No sales', 'quantity': 0};

    final topEntry = productQty.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return {'productName': topEntry.key, 'quantity': topEntry.value};
  }

  /// Find the most sold day (date with highest units sold)
  Map<String, dynamic> findMostSoldDay({
    required List<Map<String, dynamic>> sales,
  }) {
    if (sales.isEmpty) {
      return {'date': 'No data', 'unitsSold': 0};
    }

    final Map<String, int> unitsByDay = {};

    for (final sale in sales) {
      final saleDate = _parseSaleDate(sale[kSaleCreatedDate]);
      if (saleDate == null) continue;

      final dayKey =
          "${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}-${saleDate.day.toString().padLeft(2, '0')}";
      final qty = int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
      unitsByDay[dayKey] = (unitsByDay[dayKey] ?? 0) + qty;
    }

    if (unitsByDay.isEmpty) return {'date': 'No data', 'unitsSold': 0};

    final topEntry = unitsByDay.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    // Format the date nicely
    final parts = topEntry.key.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final formattedDate = "${months[date.month - 1]} ${date.day}, ${date.year}";

    return {'date': formattedDate, 'unitsSold': topEntry.value};
  }

  /// Calculate daily average revenue
  double calculateDailyAverage({
    required double totalRevenue,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final days = endDate.difference(startDate).inDays + 1;
    if (days <= 0) return totalRevenue;
    return totalRevenue / days;
  }

  /// Compare revenue with previous period
  Map<String, dynamic> compareWithPreviousPeriod({
    required List<Map<String, dynamic>> sales,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final filteredCurrent = filterSalesByDate(
      sales: sales,
      startDate: startDate,
      endDate: endDate,
    );
    final currentRevenue = calculateTotalRevenue(sales: filteredCurrent);

    final periodDuration = endDate.difference(startDate);
    final previousEndDate = startDate.subtract(const Duration(days: 1));
    final previousStartDate = previousEndDate.subtract(periodDuration);

    final filteredPrev = filterSalesByDate(
      sales: sales,
      startDate: previousStartDate,
      endDate: previousEndDate,
    );
    final previousRevenue = calculateTotalRevenue(sales: filteredPrev);

    double changePercent = 0;
    if (previousRevenue > 0) {
      changePercent =
          ((currentRevenue - previousRevenue) / previousRevenue) * 100;
    } else if (currentRevenue > 0) {
      changePercent = 100;
    }

    return {
      'currentRevenue': currentRevenue,
      'previousRevenue': previousRevenue,
      'changePercent': changePercent,
      'isIncrease': changePercent >= 0,
    };
  }
}
