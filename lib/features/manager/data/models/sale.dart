import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/features/manager/data/models/sale_item.dart';

/// Represents a sale/invoice/order
/// Contains the header information for a sale transaction
/// The actual items sold are tracked in SaleItem
class Sale {
  final String id;
  final double totalPrice;
  final DateTime createdDate;
  final String employeeUsername;
  final List<SaleItem> items;

  Sale({
    required this.id,
    required this.totalPrice,
    required this.createdDate,
    required this.employeeUsername,
    this.items = const [],
  });

  /// Create a Sale from a Map (from Google Sheets)
  /// Note: items must be loaded separately
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map[kSalesId]?.toString() ?? '',
      totalPrice:
          double.tryParse(map[kSalesTotalPrice]?.toString() ?? '0') ?? 0.0,
      createdDate:
          DateTime.tryParse(map[kSalesCreatedDate]?.toString() ?? '') ??
          DateTime.now(),
      employeeUsername: map[kSalesEmployeeUsername]?.toString() ?? '',
      items: [],
    );
  }

  /// Convert Sale to Map (for Google Sheets)
  /// Note: items should be saved separately to SalesItems sheet
  Map<String, dynamic> toMap() {
    return {
      kSalesId: id,
      kSalesTotalPrice: totalPrice.toString(),
      kSalesCreatedDate: createdDate.toIso8601String(),
      kSalesEmployeeUsername: employeeUsername,
    };
  }

  /// Create a copy with updated values
  Sale copyWith({
    String? id,
    double? totalPrice,
    DateTime? createdDate,
    String? employeeUsername,
    List<SaleItem>? items,
  }) {
    return Sale(
      id: id ?? this.id,
      totalPrice: totalPrice ?? this.totalPrice,
      createdDate: createdDate ?? this.createdDate,
      employeeUsername: employeeUsername ?? this.employeeUsername,
      items: items ?? this.items,
    );
  }

  /// Get the number of items in this sale
  int get itemCount => items.length;

  /// Get the total quantity of items sold
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  String toString() {
    return 'Sale(id: $id, total: $totalPrice, items: ${items.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sale && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
