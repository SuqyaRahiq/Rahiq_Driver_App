import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_auto_deliveries_api.dart';
import 'package:rahiq_driver/data/models/driver/driver_auto_delivery.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';

class AutoDeliveryPage extends StatefulWidget {
  const AutoDeliveryPage({super.key});

  @override
  State<AutoDeliveryPage> createState() => _AutoDeliveryPageState();
}

class _AutoDeliveryPageState extends State<AutoDeliveryPage>
    with SingleTickerProviderStateMixin {
  late DriverAutoDeliveriesApi _deliveriesApi;
  late TabController _tabController;

  List<DriverAutoDelivery> _allItems = [];
  bool _isLoading = true;
  String? _error;

  late List<_TabDef> _tabs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _tabs = [
      _TabDef(l10n.pending, ['PENDING', 'ASSIGNED', 'IN_TRANSIT', 'ACCEPTED']),
      _TabDef(l10n.delivered, ['DELIVERED', 'COMPLETED']),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _deliveriesApi = DriverAutoDeliveriesApi(ApiClient());
    _fetchItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final items = await _deliveriesApi.getAutoDeliveries();
      if (mounted) {
        setState(() {
          _allItems = items;
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

  List<DriverAutoDelivery> _deliveriesForTab(int tabIndex) {
    final statuses = _tabs[tabIndex].statuses;
    return _allItems
        .where((d) => statuses.contains((d.status ?? '').toUpperCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchItems,
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
                          0,
                          16,
                          12,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.autodelivery,
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
    final items = _deliveriesForTab(tabIndex);
    if (items.isEmpty) return _buildEmptyState(_tabs[tabIndex].label);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 150),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildItemCard(items[index]),
    );
  }

  Widget _buildItemCard(DriverAutoDelivery item) {
    final statusColor = _getStatusColor(item.status);

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to delivery details if needed
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.buttonBlueDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.buttonBlueDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.customerName ??
                          AppLocalizations.of(context)!.unknownCustomer,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Batch #${item.id.split('-').first.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                    if (item.address != null && item.address!.isNotEmpty) ...[
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
                              item.address!,
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
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatStatus(item.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
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
              Text(
                _error ?? AppLocalizations.of(context)!.somethingWentWrong,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchItems,
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
