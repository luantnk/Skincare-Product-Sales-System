import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/enhanced_cart_view_model.dart';
import '../../services/assets_manager.dart';
import '../../widgets/empty_bag.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/title_text.dart';
import 'enhanced_bottom_checkout.dart';
import 'enhanced_cart_widget.dart';

/// Màn hình Giỏ hàng cải tiến sử dụng kiến trúc MVVM
class EnhancedCartScreen extends StatefulWidget {
  const EnhancedCartScreen({super.key});

  // Route name để điều hướng
  static const routeName = '/enhanced-cart';

  @override
  State<EnhancedCartScreen> createState() => _EnhancedCartScreenState();
}

class _EnhancedCartScreenState extends State<EnhancedCartScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep the state alive when switching tabs

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Use listen: false to prevent entire screen rebuilds
    final cartViewModel = Provider.of<EnhancedCartViewModel>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: _buildAppBar(context, cartViewModel),
      body: _buildBody(context, cartViewModel),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    EnhancedCartViewModel cartViewModel,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8F5CFF),
              Color(0xFFBCA7FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 20, top: 16, bottom: 16),
                child: TitlesTextWidget(
                  label: "Giỏ hàng",
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {
                  _showClearCartDialog(context, cartViewModel);
                },
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                tooltip: 'Xóa giỏ hàng',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCartDialog(
    BuildContext context,
    EnhancedCartViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa giỏ hàng'),
            content: const Text('Bạn có chắc muốn xóa toàn bộ giỏ hàng không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  // Use post-frame callback to avoid setState during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    viewModel.clearCart();
                    Navigator.of(context).pop();
                  });
                },
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Widget _buildBody(BuildContext context, EnhancedCartViewModel cartViewModel) {
    // Use Consumer to only rebuild this part when cart state changes
    return Consumer<EnhancedCartViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Center(child: LoadingWidget());
        } else if (viewModel.hasError) {
          // Kiểm tra xem lỗi có phải là "No cart items found" không
          final errorMsg = viewModel.errorMessage?.toLowerCase() ?? '';
          if (errorMsg.contains('no cart items found') ||
              errorMsg.contains('404')) {
            // Hiển thị giỏ hàng rỗng thay vì báo lỗi
            return EmptyBagWidget(
              imagePath: AssetsManager.shoppingBasket,
              title: 'Giỏ hàng trống',
              subtitle: 'Có vẻ như bạn chưa thêm sản phẩm nào vào giỏ hàng.',
              buttonText: 'Mua sắm ngay',
            );
          }

          // Hiển thị lỗi khác
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  viewModel.errorMessage ?? 'Đã xảy ra lỗi',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.fetchCartFromServer(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        } else if (viewModel.isEmpty) {
          return EmptyBagWidget(
            imagePath: AssetsManager.shoppingBasket,
            title: 'Giỏ hàng trống',
            subtitle: 'Có vẻ như bạn chưa thêm sản phẩm nào vào giỏ hàng.',
            buttonText: 'Mua sắm ngay',
          );
        } else {
          // Màn hình có dữ liệu
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => viewModel.fetchCartFromServer(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight + 80),
                        itemCount: viewModel.cartItems.length,
                        itemBuilder: (context, index) {
                          final cartModel =
                              viewModel.cartItems.values.toList()[index];
                          return EnhancedCartWidget(
                            cartModel: cartModel,
                            viewModel: viewModel,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: kBottomNavigationBarHeight + 10),
                ],
              ),
              if (viewModel.totalPrice > 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: EnhancedCartBottomSheetWidget(viewModel: viewModel),
                ),
            ],
          );
        }
      },
    );
  }
}
