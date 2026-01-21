import 'package:gdrive_tutorial/core/consts.dart';

/// Represents a batch/lot of a product with purchase details
/// Each product can have multiple ProductItems representing different batches
/// with potentially different buy prices and expiry dates
class ProductItem {
  final String id;
  final String productId;
  final double buyPrice;
  final int quantity;
  final DateTime createdAt;
  final DateTime? expiredAt;

  ProductItem({
    required this.id,
    required this.productId,
    required this.buyPrice,
    required this.quantity,
    required this.createdAt,
    this.expiredAt,
  });

  /// Create a ProductItem from a Map (from Google Sheets)
  factory ProductItem.fromMap(Map<String, dynamic> map) {
    return ProductItem(
      id: map[kProductItemId]?.toString() ?? '',
      productId: map[kProductItemProductId]?.toString() ?? '',
      buyPrice:
          double.tryParse(map[kProductItemBuyPrice]?.toString() ?? '0') ?? 0.0,
      quantity: int.tryParse(map[kProductItemQuantity]?.toString() ?? '0') ?? 0,
      createdAt:
          DateTime.tryParse(map[kProductItemCreatedAt]?.toString() ?? '') ??
          DateTime.now(),
      expiredAt:
          map[kProductItemExpiredAt] != null &&
              map[kProductItemExpiredAt].toString().isNotEmpty
          ? DateTime.tryParse(map[kProductItemExpiredAt].toString())
          : null,
    );
  }

  /// Convert ProductItem to Map (for Google Sheets)
  Map<String, dynamic> toMap() {
    return {
      kProductItemId: id,
      kProductItemProductId: productId,
      kProductItemBuyPrice: buyPrice.toString(),
      kProductItemQuantity: quantity.toString(),
      kProductItemCreatedAt: createdAt.toIso8601String(),
      kProductItemExpiredAt: expiredAt?.toIso8601String() ?? '',
    };
  }

  /// Create a copy with updated values
  ProductItem copyWith({
    String? id,
    String? productId,
    double? buyPrice,
    int? quantity,
    DateTime? createdAt,
    DateTime? expiredAt,
  }) {
    return ProductItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      buyPrice: buyPrice ?? this.buyPrice,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      expiredAt: expiredAt ?? this.expiredAt,
    );
  }

  /// Check if this batch is expired
  bool get isExpired {
    if (expiredAt == null) return false;
    return DateTime.now().isAfter(expiredAt!);
  }

  /// Check if this batch will expire within the given days
  bool willExpireWithinDays(int days) {
    if (expiredAt == null) return false;
    final expiryThreshold = DateTime.now().add(Duration(days: days));
    return expiredAt!.isBefore(expiryThreshold);
  }

  @override
  String toString() {
    return 'ProductItem(id: $id, productId: $productId, qty: $quantity, buyPrice: $buyPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
