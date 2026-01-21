import 'package:gdrive_tutorial/core/consts.dart';

/// Represents a product in the inventory
/// This is the base product definition without quantity information
/// Quantity is tracked through ProductItem batches
class Product {
  final String id;
  final String barcode;
  final String name;
  final double sellingPrice;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.sellingPrice,
  });

  /// Create a Product from a Map (from Google Sheets)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map[kProductId]?.toString() ?? '',
      barcode: map[kProductBarcode]?.toString() ?? '',
      name: map[kProductName]?.toString() ?? '',
      sellingPrice:
          double.tryParse(map[kProductPrice]?.toString() ?? '0') ?? 0.0,
    );
  }

  /// Convert Product to Map (for Google Sheets)
  Map<String, dynamic> toMap() {
    return {
      kProductId: id,
      kProductBarcode: barcode,
      kProductName: name,
      kProductPrice: sellingPrice.toString(),
    };
  }

  /// Create a copy with updated values
  Product copyWith({
    String? id,
    String? barcode,
    String? name,
    double? sellingPrice,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      sellingPrice: sellingPrice ?? this.sellingPrice,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $sellingPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
