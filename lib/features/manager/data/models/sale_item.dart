import 'package:gdrive_tutorial/core/consts.dart';

/// Represents a line item in a sale/invoice
/// Each SaleItem belongs to a Sale and references a Product
class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final int quantity;
  final double price; // Price at time of sale

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.price,
  });

  /// Create a SaleItem from a Map (from Google Sheets)
  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map[kSalesItemId]?.toString() ?? '',
      saleId: map[kSalesItemSalesId]?.toString() ?? '',
      productId: map[kSalesItemProductId]?.toString() ?? '',
      quantity: int.tryParse(map[kSalesItemQuantity]?.toString() ?? '0') ?? 0,
      price: double.tryParse(map[kSalesItemPrice]?.toString() ?? '0') ?? 0.0,
    );
  }

  /// Convert SaleItem to Map (for Google Sheets)
  Map<String, dynamic> toMap() {
    return {
      kSalesItemId: id,
      kSalesItemSalesId: saleId,
      kSalesItemProductId: productId,
      kSalesItemQuantity: quantity.toString(),
      kSalesItemPrice: price.toString(),
    };
  }

  /// Create a copy with updated values
  SaleItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    int? quantity,
    double? price,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  /// Calculate the subtotal for this line item
  double get subtotal => price * quantity;

  @override
  String toString() {
    return 'SaleItem(id: $id, productId: $productId, qty: $quantity, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
