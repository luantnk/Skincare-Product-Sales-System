import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../providers/enhanced_order_view_model.dart';
import '../../services/jwt_service.dart';
import '../../services/currency_formatter.dart';
import '../../widgets/subtitle_text.dart';
import '../../widgets/title_text.dart';
import '../../services/my_app_function.dart';
import '../../screens/auth/login.dart';
import '../../screens/orders/order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/orders';

  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isAuthenticated = false;
  final ScrollController _scrollController = ScrollController();
  late EnhancedOrderViewModel _orderViewModel;

  // Status filter
  final List<String> _statusOptions = [
    'Tất cả',
    'Đang xử lý',
    'Đã hủy',
    'Chờ thanh toán',
    'Đã hoàn tiền',
    'Đang giao hàng',
    'Đã giao hàng',
    'Đã trả hàng',
    'Đang chờ hoàn tiền',
  ];
  String _selectedStatus = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_orderViewModel.state.hasMoreData && !_orderViewModel.state.orders.isLoadingMore) {
        _loadMoreOrders();
      }
    }
  }

  Future<void> _checkAuthentication() async {
    final isAuth = await JwtService.isAuthenticated();
    if (!isAuth) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
      return;
    }

    setState(() {
      _isAuthenticated = true;
    });

    _orderViewModel = Provider.of<EnhancedOrderViewModel>(context, listen: false);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!_isAuthenticated) return;
    await _orderViewModel.loadOrders(
      refresh: true,
      status: _selectedStatus == 'Tất cả' ? null : _convertStatusToEnglish(_selectedStatus),
    );
    if (mounted) setState(() {});
  }

  Future<void> _loadMoreOrders() async {
    await _orderViewModel.loadMoreOrders();
    if (mounted) setState(() {});
  }

  String _convertStatusToEnglish(String vietnameseStatus) {
    switch (vietnameseStatus) {
      case 'Đang xử lý':
        return 'processing';
      case 'Đã hủy':
        return 'cancelled';
      case 'Chờ thanh toán':
        return 'awaiting payment';
      case 'Đã hoàn tiền':
        return 'refunded';
      case 'Đang giao hàng':
        return 'shipping';
      case 'Đã giao hàng':
        return 'delivered';
      case 'Đã trả hàng':
        return 'returned';
      case 'Đang chờ hoàn tiền':
        return 'refund pending';
      default:
        return vietnameseStatus.toLowerCase();
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'processing':
        return '#1E90FF'; // Dodger Blue
      case 'shipped':
        return '#4169E1'; // Royal Blue
      case 'delivered':
        return '#32CD32'; // Lime Green
      case 'cancelled':
        return '#FF0000'; // Red
      default:
        return '#808080'; // Gray
    }
  }

  String _translateStatusToVietnamese(String englishStatus) {
    String status = englishStatus.toLowerCase();
    switch (status) {
      case 'processing':
        return 'Đang xử lý';
      case 'cancelled':
        return 'Đã hủy';
      case 'awaiting payment':
        return 'Chờ thanh toán';
      case 'refunded':
        return 'Đã hoàn tiền';
      case 'shipping':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã giao hàng';
      case 'returned':
        return 'Đã trả hàng';
      case 'refund pending':
        return 'Đang chờ hoàn tiền';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        centerTitle: true,
        title: const TitlesTextWidget(label: 'Đơn hàng của tôi', fontSize: 22),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(IconlyLight.arrow_left_2, size: 24),
        ),
      ),
      body: !_isAuthenticated
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status filter row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusOptions.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedStatus = status;
                              });
                              _loadOrders();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Expanded order list
                Expanded(
                  child: Consumer<EnhancedOrderViewModel>(
                    builder: (context, viewModel, _) {
                      if (viewModel.isLoading && viewModel.orders.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (!viewModel.isLoading && viewModel.orders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(IconlyBold.bag, size: 80, color: Theme.of(context).disabledColor),
                              const SizedBox(height: 16),
                              const TitlesTextWidget(label: 'Chưa có đơn hàng nào', fontSize: 18),
                              const SizedBox(height: 8),
                              const SubtitleTextWidget(label: 'Lịch sử đơn hàng của bạn sẽ hiển thị ở đây'),
                            ],
                          ),
                        );
                      } else {
                        return RefreshIndicator(
                          onRefresh: () async {
                            _loadOrders();
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: viewModel.orders.length + (viewModel.state.hasMoreData ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == viewModel.orders.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final order = viewModel.orders[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/enhanced-order-detail',
                                      arguments: order.id,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.receipt_long, size: 20),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Đơn hàng #${order.id}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: viewModel.getStatusColor(order.status).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: viewModel.getStatusColor(order.status)),
                                              ),
                                              child: Text(
                                                viewModel.getTranslatedStatus(order.status),
                                                style: TextStyle(
                                                  color: viewModel.getStatusColor(order.status),
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Ngày: ${order.createdAt.toString().split('.')[0]}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Divider(),
                                        ...order.orderDetails.map(
                                          (detail) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    detail.productName,
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  'x${detail.quantity}',
                                                  style: const TextStyle(fontSize: 13),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  CurrencyFormatter.formatVND(detail.price),
                                                  style: const TextStyle(fontSize: 13, color: Colors.blue),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Divider(),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Tổng cộng:',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              CurrencyFormatter.formatVND(order.totalAmount),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
