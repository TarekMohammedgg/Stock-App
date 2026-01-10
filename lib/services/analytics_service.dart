// import 'dart:developer';
// import 'package:gdrive_tutorial/core/consts.dart';
// import 'package:gdrive_tutorial/services/gsheet_service.dart';

// /// Service for calculating analytics and insights
// class AnalyticsService {
//   final GSheetService _sheetsService;

//   AnalyticsService(this._sheetsService);

//   /// Get comprehensive analytics data
//   Future<Map<String, dynamic>> getAnalytics({
//     required String spreadsheetId,
//     DateTime? startDate,
//     DateTime? endDate,
//   }) async {
//     try {
//       // Fetch all products and sales
//       final products = await _sheetsService.getProducts();
//       final sales = await _sheetsService.getSales();

//       // Calculate metrics
//       final totalProducts = products?.length ?? 0;
//       final totalSales = sales?.length ?? 0;

//       // Calculate revenue
//       double totalRevenue = 0;
//       if (sales != null) {
//         for (var sale in sales) {
//           final price =
//               double.tryParse(sale[kSaleProductPrice]?.toString() ?? '0') ?? 0;
//           final quantity =
//               int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
//           totalRevenue += price * quantity;
//         }
//       }

//       // Calculate average sale value
//       final averageSaleValue = totalSales > 0 ? totalRevenue / totalSales : 0;

//       // Find low stock products
//       final lowStockProducts = products?.where((product) {
//         final quantity =
//             int.tryParse(product[kProductQuantity]?.toString() ?? '0') ?? 0;
//         return quantity <= kLowStockThreshold;
//       }).toList();

//       // Find top selling products
//       final productSalesMap = <String, int>{};
//       if (sales != null) {
//         for (var sale in sales) {
//           final productId = sale[kSaleProductId]?.toString() ?? '';
//           final quantity =
//               int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
//           productSalesMap[productId] =
//               (productSalesMap[productId] ?? 0) + quantity;
//         }
//       }

//       // Get top 5 products
//       final topProducts = productSalesMap.entries.toList()
//         ..sort((a, b) => b.value.compareTo(a.value));

//       final top5Products = topProducts.take(5).map((entry) {
//         final product = products?.firstWhere(
//           (p) => p[kProductId] == entry.key,
//           orElse: () => <String, dynamic>{}, // Ensure orElse returns a Map
//         );
//         return {
//           'productId': entry.key,
//           'productName':
//               product?[kProductName] ?? 'Unknown', // Null-safe access
//           'quantitySold': entry.value,
//           'price': product?[kProductPrice] ?? '0', // Null-safe access
//         };
//       }).toList();

//       // Calculate daily sales (last 7 days)
//       final now = DateTime.now();
//       final dailySales = <String, double>{};

//       for (var i = 6; i >= 0; i--) {
//         final date = now.subtract(Duration(days: i));
//         final dateKey = '${date.month}/${date.day}';
//         dailySales[dateKey] = 0;
//       }

//       if (sales != null) {
//         for (var sale in sales) {
//           try {
//             final createdDate = DateTime.parse(
//               sale[kSaleCreatedDate]?.toString() ?? '',
//             );
//             final dateKey = '${createdDate.month}/${createdDate.day}';

//             if (dailySales.containsKey(dateKey)) {
//               final price =
//                   double.tryParse(sale[kSaleProductPrice]?.toString() ?? '0') ??
//                   0;
//               final quantity =
//                   int.tryParse(sale[kSaleQuantity]?.toString() ?? '0') ?? 0;
//               dailySales[dateKey] =
//                   (dailySales[dateKey] ?? 0) + (price * quantity);
//             }
//           } catch (e) {
//             log('Error parsing sale date: $e');
//           }
//         }
//       }

//       return {
//         'totalProducts': totalProducts,
//         'totalSales': totalSales,
//         'totalRevenue': totalRevenue,
//         'averageSaleValue': averageSaleValue,
//         'lowStockProducts': lowStockProducts?.toList() ?? [],
//         'topProducts': top5Products,
//         'dailySales': dailySales,
//         'lowStockCount': lowStockProducts?.length ?? 0,
//       };
//     } catch (e) {
//       log('❌ Error calculating analytics: $e');
//       rethrow;
//     }
//   }

//   /// Get inventory health metrics
//   Future<Map<String, dynamic>> getInventoryHealth({
//     required String spreadsheetId,
//   }) async {
//     try {
//       final products = await _sheetsService.getProducts();

//       int adequateStock = 0;
//       int lowStock = 0;
//       int outOfStock = 0;
//       double totalInventoryValue = 0;

//       if (products != null) {
//         for (var product in products) {
//           final quantity =
//               int.tryParse(product[kProductQuantity]?.toString() ?? '0') ?? 0;
//           final price =
//               double.tryParse(product[kProductPrice]?.toString() ?? '0') ?? 0;

//           totalInventoryValue += quantity * price;

//           if (quantity == 0) {
//             outOfStock++;
//           } else if (quantity <= kLowStockThreshold) {
//             lowStock++;
//           } else if (quantity >= kAdequateStockThreshold) {
//             adequateStock++;
//           }
//         }
//       }

//       return {
//         'adequateStock': adequateStock,
//         'lowStock': lowStock,
//         'outOfStock': outOfStock,
//         'totalInventoryValue': totalInventoryValue,
//         'totalProducts': products?.length ?? 0,
//       };
//     } catch (e) {
//       log('❌ Error calculating inventory health: $e');
//       rethrow;
//     }
//   }
// }
