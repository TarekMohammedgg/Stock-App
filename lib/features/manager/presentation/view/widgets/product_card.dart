import 'package:flutter/material.dart';
import 'package:gdrive_tutorial/core/consts.dart';
import 'package:gdrive_tutorial/core/widgets/product_image_widget.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = product[kProductName]?.toString() ?? 'Unknown';
    final barcode = product[kProductBarcode]?.toString() ?? 'N/A';
    final price = product[kProductPrice]?.toString() ?? '0';
    final quantity = product[kProductQuantity]?.toString() ?? '0';
    final imageUrl = product[kProductImageUrl]
        ?.toString(); // Don't convert here - widget does it

    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onEdit,
      child: Card(
        elevation: 2,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: ProductImageWidget(
            imageUrl: imageUrl,
            size: 50,
            fallbackIcon: Icons.inventory_2,
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Barcode: $barcode',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '\$$price',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.secondary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Stock: $quantity',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            color: colorScheme.surface,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Edit',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
          ),
        ),
      ),
    );
  }
}
