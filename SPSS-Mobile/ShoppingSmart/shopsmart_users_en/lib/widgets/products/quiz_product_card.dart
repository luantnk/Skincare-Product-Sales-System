import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/enhanced_products_view_model.dart';
import 'package:shopsmart_users_en/screens/inner_screen/enhanced_product_detail.dart';

class QuizProductCard extends StatelessWidget {
  final String? productId;
  final Map<String, dynamic>? product;

  const QuizProductCard({super.key, this.productId, this.product})
    : assert(
        productId != null || product != null,
        'Either productId or product must be provided',
      );

  String getPlainDescription(Map<String, dynamic>? product) {
    if (product == null) return '';
    final desc = product['description'] ?? '';
    // Loại bỏ tag HTML nếu có
    return desc.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
  }

  @override
  Widget build(BuildContext context) {
    // If product is directly provided, use it
    if (product != null) {
      return _buildProductCard(context, product!);
    }

    // Otherwise fetch product by ID
    final productsViewModel = Provider.of<EnhancedProductsViewModel>(
      context,
      listen: false,
    );

    return FutureBuilder<Map<String, dynamic>?>(
      future: productsViewModel.getProductById(productId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Không thể tải sản phẩm',
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
            ),
          );
        }

        final product = snapshot.data!;
        return _buildProductCard(context, product);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        EnhancedProductDetailsScreen.routeName,
        arguments: product['id'],
      ),
      child: Container(
        width: 180,
        height: 260, // Tăng chiều cao card để tránh tràn
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần hình ảnh
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product['thumbnail'] ?? '',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                  ),
                  if (product['discountPercentage'] != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "-${product['discountPercentage']?.toString().split('.').first ?? '0'}%",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Phần tiêu đề sản phẩm
            SizedBox(
              height: 36,
              child: Text(
                product['name'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Phần mô tả sản phẩm
            Flexible(
              child: Text(
                getPlainDescription(product),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            const Spacer(),
            // Phần giá và nút
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    '${product['price']?.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 8,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    EnhancedProductDetailsScreen.routeName,
                    arguments: product['id'],
                  ),
                  child: const Text('Xem chi tiết'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
