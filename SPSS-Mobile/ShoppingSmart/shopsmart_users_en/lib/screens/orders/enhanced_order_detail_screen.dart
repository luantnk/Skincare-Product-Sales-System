import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:provider/provider.dart';

import '../../widgets/product_review_modal.dart';
import '../../screens/inner_screen/enhanced_product_detail.dart';

import '../../models/order_models.dart';
import '../../providers/enhanced_order_view_model.dart';
import '../../providers/order_state.dart';
import '../../screens/mvvm_screen_template.dart';
import '../../services/currency_formatter.dart';

class EnhancedOrderDetailScreen extends StatelessWidget {
  static const routeName = '/enhanced-order-detail';
  final String orderId;

  const EnhancedOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return MvvmScreenTemplate<EnhancedOrderViewModel, OrderState>(
      title: 'Chi tiết đơn hàng',
      onInit: (viewModel) => viewModel.loadOrderDetail(orderId),
      isLoading: (viewModel) => viewModel.isLoadingOrderDetail,
      getErrorMessage:
          (viewModel) =>
              viewModel.state.selectedOrder.hasError
                  ? viewModel.state.selectedOrder.message
                  : null,
      buildAppBar: (context, viewModel) => _buildAppBar(context),
      buildContent: (context, viewModel) => _buildContent(context, viewModel),
      onRefresh: (viewModel) => viewModel.loadOrderDetail(orderId),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8F5CFF), Color(0xFFBCA7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Chi tiết đơn hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EnhancedOrderViewModel viewModel) {
    final orderDetail = viewModel.selectedOrder;
    if (orderDetail == null) {
      return const Center(child: Text('Không tìm thấy thông tin đơn hàng'));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildOrderStatusCard(context, orderDetail),
          if (orderDetail.statusChanges.isNotEmpty)
            _buildStatusTimeline(context, orderDetail.statusChanges),
          _buildOrderSummaryCard(context, orderDetail),
          _buildShippingAddressCard(context, orderDetail),
          _buildOrderItemsCard(context, orderDetail),
          _buildOrderActionsCard(context, orderDetail, viewModel),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(
    BuildContext context,
    List<StatusChangeModel> statusChanges,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8F5CFF).withOpacity(0.13)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.history, color: Color(0xFF8F5CFF)),
              SizedBox(width: 8),
              Text('Lịch sử đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8F5CFF), fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: statusChanges.length,
            itemBuilder: (context, index) {
              final isFirst = index == 0;
              final isLast = index == statusChanges.length - 1;
              final statusChange = statusChanges[index];
              return TimelineTile(
                alignment: TimelineAlign.manual,
                lineXY: 0.2,
                isFirst: isFirst,
                isLast: isLast,
                indicatorStyle: IndicatorStyle(
                  width: 20,
                  color: isLast ? Colors.green : const Color(0xFF8F5CFF),
                  iconStyle: IconStyle(
                    color: Colors.white,
                    iconData: isLast ? Icons.check : Icons.circle,
                    fontSize: isLast ? 14 : 12,
                  ),
                ),
                beforeLineStyle: const LineStyle(
                  color: Color(0xFF8F5CFF),
                ),
                endChild: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translateStatus(statusChange.status),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(statusChange.date),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                startChild: Center(
                  child: Text(
                    _formatTimeOnly(statusChange.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8F5CFF),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard(
    BuildContext context,
    OrderDetailModel orderDetail,
  ) {
    final statusColor = _getStatusColor(orderDetail.status);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getStatusIcon(orderDetail.status), color: statusColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translateStatus(orderDetail.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cập nhật: ${DateFormat('dd/MM/yyyy - HH:mm').format(orderDetail.createdTime)}',
                      style: TextStyle(color: statusColor.withOpacity(0.7), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Mã đơn hàng', style: TextStyle(color: statusColor.withOpacity(0.7), fontSize: 14)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.18)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    orderDetail.id,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: statusColor, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: orderDetail.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép mã đơn hàng'), backgroundColor: Colors.green),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(
    BuildContext context,
    OrderDetailModel orderDetail,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8F5CFF).withOpacity(0.13)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.receipt_long, color: Color(0xFF8F5CFF)),
              SizedBox(width: 8),
              Text('Tóm tắt đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8F5CFF), fontSize: 16)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng tiền gốc:', style: TextStyle(fontSize: 15)),
              Text(CurrencyFormatter.format(orderDetail.originalOrderTotal), style: const TextStyle(fontSize: 15)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                CurrencyFormatter.format(orderDetail.discountedOrderTotal),
                style: const TextStyle(
                  color: Color(0xFF8F5CFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddressCard(
    BuildContext context,
    OrderDetailModel orderDetail,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8F5CFF).withOpacity(0.13)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.location_on, color: Color(0xFF8F5CFF)),
                SizedBox(width: 8),
                Text('Địa chỉ giao hàng', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8F5CFF), fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              orderDetail.address.customerName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(orderDetail.address.phoneNumber),
            const SizedBox(height: 8),
            Text(
              '${orderDetail.address.addressLine1}, '
              '${orderDetail.address.ward}, '
              '${orderDetail.address.city}, '
              '${orderDetail.address.province}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard(
    BuildContext context,
    OrderDetailModel orderDetail,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8F5CFF).withOpacity(0.13)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.shopping_bag, color: Color(0xFF8F5CFF)),
                SizedBox(width: 8),
                Text('Sản phẩm đã mua', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8F5CFF), fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orderDetail.orderDetails.length,
              itemBuilder: (context, index) {
                final item = orderDetail.orderDetails[index];
                return _buildOrderItemCard(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemCard(BuildContext context, OrderDetail item) {
    return InkWell(
      onTap: () {
        // Navigate to product details screen when tapped
        Navigator.of(context).pushNamed(
          EnhancedProductDetailsScreen.routeName,
          arguments: item.productId,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.productImage,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  if (item.variationOptionValues.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.variationOptionValues.join(", "),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormatter.formatVND(item.price),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('SL: ${item.quantity}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActionsCard(
    BuildContext context,
    OrderDetailModel orderDetail,
    EnhancedOrderViewModel viewModel,
  ) {
    // Hiển thị nút hủy đơn hàng chỉ khi đơn hàng đang ở trạng thái có thể hủy
    final canCancel = _canCancelOrder(orderDetail.status);
    // Có thể đánh giá nếu đơn hàng đã giao VÀ có ít nhất một sản phẩm có thể đánh giá
    final canReview =
        orderDetail.status.toLowerCase() == 'delivered' &&
        orderDetail.orderDetails.any((item) => item.isReviewable);

    if (!canCancel && !canReview) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thao tác',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            if (canCancel)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed:
                      () =>
                          _confirmCancelOrder(context, orderDetail, viewModel),
                  child: const Text(
                    'Hủy đơn hàng',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            if (canReview) ...[
              if (canCancel) const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed:
                      () => _navigateToReviewProducts(context, orderDetail),
                  child: const Text(
                    'Đánh giá sản phẩm',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancelOrder(
    BuildContext context,
    OrderDetailModel orderDetail,
    EnhancedOrderViewModel viewModel,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận hủy đơn hàng'),
            content: const Text(
              'Bạn có chắc chắn muốn hủy đơn hàng này? '
              'Hành động này không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Không'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Có, hủy đơn hàng'),
              ),
            ],
          ),
    );

    if (result == true) {
      final success = await viewModel.cancelOrder(orderDetail.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đã hủy đơn hàng thành công'
                  : 'Không thể hủy đơn hàng. Vui lòng thử lại sau.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          viewModel.loadOrderDetail(orderDetail.id);
        }
      }
    }
  }

  void _navigateToReviewProducts(
    BuildContext context,
    OrderDetailModel orderDetail,
  ) {
    // Lấy bản sao của orderDetail để có thể cập nhật trạng thái ngay lập tức
    final orderDetails = List<OrderDetail>.from(orderDetail.orderDetails);

    // Đảm bảo xóa hết state review trước khi mở modal
    final viewModel = Provider.of<EnhancedOrderViewModel>(
      context,
      listen: false,
    );
    viewModel.cleanupReviewImages();

    // Hiển thị dialog cho người dùng chọn sản phẩm để đánh giá
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Chọn sản phẩm để đánh giá',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orderDetails.length,
                        itemBuilder: (context, index) {
                          final item = orderDetails[index];
                          return ListTile(
                            enabled: item.isReviewable,
                            onTap:
                                item.isReviewable
                                    ? () {
                                      Navigator.of(context).pop();
                                      // Đánh giá sản phẩm
                                      ProductReviewModal.show(
                                        context,
                                        item.productItemId,
                                        item.productName,
                                        item.productImage,
                                        orderId: orderId,
                                      ).then((_) {
                                        // Cập nhật trạng thái UI ngay lập tức
                                        if (context.mounted) {
                                          // Cập nhật trạng thái UI ngay lập tức
                                          setState(() {
                                            // Tìm và cập nhật sản phẩm đã đánh giá
                                            final productIndex = orderDetails
                                                .indexWhere(
                                                  (p) =>
                                                      p.productItemId ==
                                                      item.productItemId,
                                                );
                                            if (productIndex >= 0) {
                                              orderDetails[productIndex] =
                                                  orderDetails[productIndex]
                                                      .copyWith(
                                                        isReviewable: false,
                                                      );
                                            }
                                          });

                                          // Hiển thị lại modal nếu còn sản phẩm có thể đánh giá
                                          if (orderDetails.any(
                                            (item) => item.isReviewable,
                                          )) {
                                            _navigateToReviewProducts(
                                              context,
                                              orderDetail,
                                            );
                                          }
                                        }
                                      });
                                    }
                                    : null,
                            leading: Stack(
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: item.productImage,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error),
                                          ),
                                      color:
                                          item.isReviewable
                                              ? null
                                              : Colors.grey,
                                      colorBlendMode:
                                          item.isReviewable
                                              ? null
                                              : BlendMode.saturation,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        // Navigate to product details when image is tapped
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pushNamed(
                                          EnhancedProductDetailsScreen
                                              .routeName,
                                          arguments: item.productId,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              item.productName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.isReviewable ? null : Colors.grey,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.variationOptionValues.isNotEmpty)
                                  Text(
                                    item.variationOptionValues.join(", "),
                                    style: TextStyle(
                                      color:
                                          item.isReviewable
                                              ? null
                                              : Colors.grey,
                                    ),
                                  ),
                                if (!item.isReviewable)
                                  const Text(
                                    'Bạn đã đánh giá sản phẩm này',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'awaiting payment':
        return Icons.payment;
      case 'processing':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.inventory;
      case 'shipped':
      case 'shipping':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      case 'refunded':
        return Icons.money_off;
      case 'returned':
        return Icons.keyboard_return;
      default:
        return Icons.info;
    }
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'awaiting payment':
        return 'Chờ thanh toán';
      case 'processing':
        return 'Đang xử lý';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'shipped':
      case 'shipping':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã giao hàng';
      case 'cancelled':
        return 'Đã hủy';
      case 'refunded':
        return 'Đã hoàn tiền';
      case 'returned':
        return 'Đã trả hàng';
      case 'refund pending':
        return 'Đang chờ hoàn tiền';
      default:
        return status;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Chuyển đổi sang múi giờ Việt Nam (UTC+7)
    final vietnamTime = dateTime.add(const Duration(hours: 7));
    return DateFormat('dd/MM/yyyy - HH:mm').format(vietnamTime);
  }

  String _formatTimeOnly(DateTime dateTime) {
    // Chuyển đổi sang múi giờ Việt Nam (UTC+7)
    final vietnamTime = dateTime.add(const Duration(hours: 7));
    return DateFormat('HH:mm').format(vietnamTime);
  }

  bool _canCancelOrder(String status) {
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'awaiting payment' ||
        lowerStatus == 'processing' ||
        lowerStatus == 'confirmed';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA500); // Orange
      case 'processing':
        return const Color(0xFF1E90FF); // Dodger Blue
      case 'shipped':
        return const Color(0xFF4169E1); // Royal Blue
      case 'delivered':
        return const Color(0xFF32CD32); // Lime Green
      case 'cancelled':
        return const Color(0xFFFF0000); // Red
      default:
        return const Color(0xFF808080); // Gray
    }
  }
}
