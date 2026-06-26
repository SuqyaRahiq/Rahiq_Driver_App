import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_orders_api.dart';
import 'package:rahiq_driver/pages/orders/order_details_page.dart';
import 'package:rahiq_driver/pages/orders/auto_order_details_page.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';

class OrderListItem {
  final String id;
  final String title;
  final String subtitle;
  final String? address;
  final String status;
  final DateTime? createdAt;
  final bool isAuto;
  final dynamic originalModel;
  final String? imageUrl;

  OrderListItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.address,
    required this.status,
    this.createdAt,
    required this.isAuto,
    required this.originalModel,
    this.imageUrl,
  });
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late DriverOrdersApi _ordersApi;
  late TabController _tabController;

  List<OrderListItem> _allOrders = [];
  bool _isLoading = true;
  String? _error;

  late List<_TabDef> _tabs;

  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _tabs = [_TabDef(l10n.normalOrders, []), _TabDef(l10n.autoOrders, [])];
    if (_isInit) {
      _isInit = false;
      _fetchOrders();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ordersApi = DriverOrdersApi(ApiClient());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final normalOrders = await _ordersApi.getNormalOrders();
      final autoOrders = await _ordersApi.getAutoOrders();

      final List<OrderListItem> combined = [];

      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      for (var order in normalOrders) {
        final title =
            (isArabic ? (order.nameAr ?? order.name) : order.name) ??
            order.customerName ??
            'Unknown Customer';

        String address = '';
        if (order.city != null) {
          final cityName = isArabic
              ? (order.city!['nameAr'] ?? order.city!['name'])
              : order.city!['name'];
          address = cityName ?? '';
        }
        if (order.deliveryAddress != null && address.isEmpty) {
          address = order.deliveryAddress!;
        }

        if (order.totalQuantity != null) {
          if (address.isNotEmpty) {
            address = '${order.totalQuantity} packages • $address';
          } else {
            address = '${order.totalQuantity} packages';
          }
        }

        combined.add(
          OrderListItem(
            id: order.id,
            title: title,
            subtitle: l10n.orderNumber(order.id.split('-').first.toUpperCase()),
            address: address.isEmpty ? null : address,
            status: order.status ?? 'PENDING',
            createdAt: order.createdAt,
            isAuto: false,
            originalModel: order,
            imageUrl: order.image,
          ),
        );
      }

      for (var auto in autoOrders) {
        combined.add(
          OrderListItem(
            id: auto.id,
            title: auto.name,
            subtitle: l10n.autoOrderNumber(auto.id),
            address: '${auto.totalQuantity} packages',
            status:
                'PENDING', // Default to pending so it appears in the Assigned tab
            createdAt: null, // Auto orders don't have createdAt
            isAuto: true,
            originalModel: auto,
            imageUrl: auto.image,
          ),
        );
      }

      combined.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      if (mounted) {
        setState(() {
          _allOrders = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<OrderListItem> _ordersForTab(int tabIndex) {
    if (tabIndex == 0) {
      return _allOrders.where((o) => !o.isAuto).toList();
    } else {
      return _allOrders.where((o) => o.isAuto).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: AppColors.buttonBlueDark,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: AppColors.buttonBlueDark,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          16,
                          16,
                          12,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.orders,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.viewAndManageAssignedOrders,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Rounded white body ───────────────────────────────────────────
              Stack(
                children: [
                  Container(height: 50, color: AppColors.buttonBlueDark),
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            height: 55,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                color: AppColors.buttonBlueDark,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey[600],
                              labelStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              tabs: _tabs
                                  .map((t) => Tab(text: t.label))
                                  .toList(),
                              onTap: (_) => setState(() {}),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _isLoading
                            ? SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.buttonBlueDark,
                                  ),
                                ),
                              )
                            : _error != null
                            ? _buildErrorState()
                            : AnimatedBuilder(
                                animation: _tabController,
                                builder: (context, _) {
                                  return _buildTabContent(_tabController.index);
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(int tabIndex) {
    final orders = _ordersForTab(tabIndex);
    if (orders.isEmpty) return _buildEmptyState(_tabs[tabIndex].label);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 150),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }

  Widget _buildOrderCard(OrderListItem order) {
    final statusColor = _getStatusColor(order.status);

    return Material(
      color: Colors.white,
      elevation: 2,

      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (order.isAuto) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AutoOrderDetailsPage(item: order.originalModel),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsPage(order: order.originalModel),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (order.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: order.imageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 64,
                        height: 64,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      return Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.buttonBlueDark.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: AppColors.buttonBlueDark,
                          size: 32,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlueDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.buttonBlueDark,
                    size: 32,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),

                    if (order.address != null && order.address!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: Colors.black38,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              order.address!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String tabLabel) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.buttonBlueDark.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 40,
                color: AppColors.buttonBlueDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noOrders(tabLabel),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    _error ?? AppLocalizations.of(context)!.somethingWentWrong,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBlueDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.tryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStatus(String? status) {
    if (status == null) return 'PENDING';
    return status.replaceAll('_', ' ');
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'DELIVERED':
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      case 'IN_TRANSIT':
        return Colors.orange;
      case 'ASSIGNED':
      case 'ACCEPTED':
        return AppColors.buttonBlueDark;
      default:
        return Colors.blueGrey;
    }
  }
}

class _TabDef {
  final String label;
  final List<String> statuses;
  const _TabDef(this.label, this.statuses);
}
