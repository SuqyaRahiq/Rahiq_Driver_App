import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_auto_deliveries_api.dart';
import 'package:rahiq_driver/data/models/driver/driver_auto_delivery.dart';
import 'package:rahiq_driver/pages/shared/proof_submission_page.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/shimmer_loading.dart';

class AutoDeliveryPage extends StatefulWidget {
  const AutoDeliveryPage({super.key});

  @override
  State<AutoDeliveryPage> createState() => _AutoDeliveryPageState();
}

class _AutoDeliveryPageState extends State<AutoDeliveryPage> {
  late DriverAutoDeliveriesApi _deliveriesApi;

  List<DriverAutoDelivery> _allItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _deliveriesApi = DriverAutoDeliveriesApi(ApiClient());
    _fetchItems();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchItems,
        color: AppColors.buttonBlueDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        _isLoading
                            ? const ListShimmerLoader(itemCount: 10)
                            : _error != null
                            ? _buildErrorState()
                            : _buildContent(),
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

  Widget _buildContent() {
    if (_allItems.isEmpty) {
      return _buildEmptyState(AppLocalizations.of(context)!.autodelivery);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
      itemCount: _allItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildOrderCard(_allItems[index]),
    );
  }

  Widget _buildOrderCard(DriverAutoDelivery order) {
    final bool isAr = Directionality.of(context) == TextDirection.rtl;
    return Material(
      color: Colors.white,
      elevation: 1,

      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return ProofSubmissionPage(
                  autoDelivery: order,
                  orderId: order.id,
                  isAutoOrder: false,
                  isAutoDelivery: true,
                  subOrders: [],
                );
              },
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // if (order.product?.image != null)
                    //   ClipRRect(
                    //     borderRadius: BorderRadius.circular(12),
                    //     child: CachedNetworkImage(
                    //       imageUrl: order.product!.image!,
                    //       width: 64,
                    //       height: 64,
                    //       fit: BoxFit.cover,
                    //       placeholder: (context, url) => Shimmer.fromColors(
                    //         baseColor: Colors.grey[300]!,
                    //         highlightColor: Colors.grey[100]!,
                    //         child: Container(
                    //           width: 64,
                    //           height: 64,
                    //           color: Colors.white,
                    //         ),
                    //       ),
                    //       errorWidget: (context, url, error) {
                    //         return Container(
                    //           width: 64,
                    //           height: 64,
                    //           padding: const EdgeInsets.all(12),
                    //           decoration: BoxDecoration(
                    //             color: AppColors.buttonBlueDark.withValues(
                    //               alpha: 0.08,
                    //             ),
                    //             borderRadius: BorderRadius.circular(12),
                    //           ),
                    //           child: Icon(
                    //             Icons.mosque,
                    //             color: AppColors.buttonBlueDark,
                    //             size: 32,
                    //           ),
                    //         );
                    //       },
                    //     ),
                    //   )
                    // else
                    //   Container(
                    //     width: 64,
                    //     height: 64,
                    //     padding: const EdgeInsets.all(12),
                    //     decoration: BoxDecoration(
                    //       color: AppColors.buttonBlueDark.withValues(
                    //         alpha: 0.08,
                    //       ),
                    //       borderRadius: BorderRadius.circular(12),
                    //     ),
                    //     child: Icon(
                    //       Icons.mosque,
                    //       color: AppColors.buttonBlueDark,
                    //       size: 32,
                    //     ),
                    //   ),
                    // const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? order.deliveryLocation!.campaign!.titleAr ??
                                      'No Name'
                                : order.deliveryLocation!.campaign!.title ??
                                      'No Name',

                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (order.deliveryLocation?.campaign != null) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 20,
                                  color: AppColors.buttonBlueDark,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isAr
                                      ? order.product?.nameAr ?? 'No Name'
                                      : order.product?.name ?? 'No Name',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.buttonBlueDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 3),
                          if (order.quantity != 0 && order.orderCount != 0) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Symbols.package_2,
                                      size: 20,
                                      color: AppColors.buttonBlueDark,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      "${order.quantity} ${AppLocalizations.of(context)!.packages}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.buttonBlueDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Symbols.delivery_truck_speed,
                                      size: 20,
                                      color: AppColors.buttonBlueDark,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      "${order.orderCount} ${AppLocalizations.of(context)!.orders}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.buttonBlueDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
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
}
