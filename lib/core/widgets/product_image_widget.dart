import 'package:flutter/material.dart';
// import 'package:gdrive_tutorial/core/app_theme.dart';
import 'package:gdrive_tutorial/services/gdrive_service.dart';
import 'dart:developer';

/// Widget to display product image from URL or fallback icon
/// Simple and organized image display component
/// Automatically converts Google Drive URLs to direct image URLs
class ProductImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final IconData fallbackIcon;

  const ProductImageWidget({
    super.key,
    this.imageUrl,
    this.size = 50,
    this.fallbackIcon = Icons.inventory_2,
  });

  @override
  Widget build(BuildContext context) {
    // Convert Google Drive URL to direct image URL
    final directImageUrl = GDriveService.convertToDirectImageUrl(imageUrl);

    // Debug logging
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      log('📷 Original URL: $imageUrl');
      log('📷 Converted URL: $directImageUrl');
    }

    // Check if image URL exists and is not empty
    if (directImageUrl != null && directImageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          directImageUrl, // Use converted URL
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              log('✅ Image loaded: $directImageUrl');
              return child;
            }
            log('⏳ Loading: $directImageUrl');
            return _buildLoadingPlaceholder(context);
          },
          errorBuilder: (context, error, stackTrace) {
            log('❌ Error loading image: $error');
            log('❌ Failed URL: $directImageUrl');
            return _buildIconFallback(context);
          },
        ),
      );
    }

    // No image URL, show icon
    return _buildIconFallback(context);
  }

  Widget _buildIconFallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(fallbackIcon, color: colorScheme.primary, size: size * 0.6),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
