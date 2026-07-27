import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_orders_api.dart';
import 'package:rahiq_driver/data/models/driver/normal_sub_order.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/shimmer_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rahiq_driver/pages/profile/past_order_details.dart';
import 'dart:async';
import 'package:intl/intl.dart' hide TextDirection;

class PastOrdersPage extends StatefulWidget {
  const PastOrdersPage({super.key});

  @override
  State<PastOrdersPage> createState() => _PastOrdersPageState();
}

class _PastOrdersPageState extends State<PastOrdersPage>
    with SingleTickerProviderStateMixin {
  late DriverOrdersApi _ordersApi;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<NormalSubOrder> _orders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  final int _limit = 30;
  bool _hasMore = true;

  String _currentStatus = 'DELIVERED'; // default tab
  String? _searchQuery;
  String? _orderType; // 'NORMAL' or 'AUTO'
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isTypeMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _ordersApi = DriverOrdersApi(ApiClient());
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _fetchOrders(refresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final newStatus = _tabController.index == 0 ? 'DELIVERED' : 'CONFIRMED';
      if (_currentStatus != newStatus) {
        setState(() {
          _currentStatus = newStatus;
        });
        _fetchOrders(refresh: true);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchOrders(refresh: false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
        _fetchOrders(refresh: true);
      }
    });
  }

  // ── Themed Date Range Picker ────────────────────────────────────────────
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      switchToCalendarEntryModeIcon: Icon(
        Icons.calendar_month_outlined,
        color: Colors.white,
      ),
      context: context,
      locale: Localizations.localeOf(context),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (context, child) {
        final baseTheme = Theme.of(context);

        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: AppColors.buttonBlueDark,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              // Header (the big "Start Date - End Date" bar at the top)
              headerBackgroundColor: AppColors.buttonBlueDark,
              headerForegroundColor: Colors.white,
              headerHeadlineStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              // Range specific styling
              rangePickerHeaderBackgroundColor: AppColors.buttonBlueDark,
              rangePickerHeaderForegroundColor: Colors.white,
              rangePickerBackgroundColor: Colors.white,
              rangeSelectionBackgroundColor: AppColors.buttonBlueDark
                  .withValues(alpha: 0.12),
              // Day cells
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey.shade400;
                }
                return Colors.black87;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.buttonBlueDark;
                }
                return null;
              }),
              dayOverlayColor: WidgetStateProperty.all(
                AppColors.buttonBlueDark.withValues(alpha: 0.08),
              ),
              todayForegroundColor: WidgetStateProperty.all(
                AppColors.buttonBlueDark,
              ),
              todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
              todayBorder: const BorderSide(
                color: AppColors.buttonBlueDark,
                width: 1,
              ),
              // Year picker
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.black87;
              }),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.buttonBlueDark;
                }
                return null;
              }),
              // Shape of the whole dialog
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.buttonBlueDark,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // IMPORTANT: return `child` as-is (just re-themed). `child` is the
          // full DateRangePickerDialog, which is itself a Dialog and already
          // handles its own sizing + keyboard-aware repositioning internally
          // (via AnimatedPadding tied to MediaQuery.viewInsets). Wrapping it
          // in our own fixed-height ConstrainedBox/ClipRRect breaks that: when
          // the keyboard opens in text-entry mode, the inner Dialog pushes its
          // content up to stay visible but gets clipped by our outer box
          // instead of resizing, making content appear to disappear. The
          // rounded white look is already handled above via
          // datePickerTheme.shape / backgroundColor, so no extra wrapper is
          // needed here.
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _fetchOrders(refresh: true);
    }
  }

  void _clearDateRange() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _fetchOrders(refresh: true);
  }

  Future<void> _fetchOrders({required bool refresh}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _isLoading = true;
        _error = null;
        _hasMore = true;
        _orders.clear();
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final response = await _ordersApi.getPastOrders(
        page: _page,
        limit: _limit,
        status: _currentStatus,
        search: _searchQuery,
        from: _fromDate != null
            ? DateFormat('yyyy-MM-dd').format(_fromDate!)
            : null,
        to: _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null,
        orderType: _orderType,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _orders = response.items;
          } else {
            _orders.addAll(response.items);
          }
          _page++;
          _hasMore = response.items.length >= _limit;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => _fetchOrders(refresh: true),
        color: AppColors.buttonBlueDark,
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAr ? 'الطلبات السابقة' : 'Past Orders',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 38),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Rounded white body ───────────────────────────────────────────
          Expanded(
            child: Stack(
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
                      // Pill-shaped TabBar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                          elevation: 1,
                          borderRadius: BorderRadius.circular(25),
                          color: Colors.white,
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TabBar(
                              splashFactory: NoSplash.splashFactory,
                              splashBorderRadius: BorderRadius.circular(25),
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
                              tabs: [
                                Tab(text: isAr ? 'تم التوصيل' : 'Delivered'),
                                Tab(text: isAr ? 'مؤكد' : 'Confirmed'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filters & Search
                      _buildFiltersAndSearch(isAr),
                      const SizedBox(height: 12),

                      // List View
                      Expanded(
                        child: _isLoading
                            ? const SingleChildScrollView(
                                child: ListShimmerLoader(itemCount: 10),
                              )
                            : _error != null
                            ? _buildErrorState()
                            : _buildContent(isAr),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFiltersAndSearch(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: isAr ? 'بحث' : 'Search',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Type Filter
                PopupMenuButton<String>(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  position: PopupMenuPosition.under,
                  onOpened: () => setState(() => _isTypeMenuOpen = true),
                  onCanceled: () => setState(() => _isTypeMenuOpen = false),
                  onSelected: (val) {
                    setState(() {
                      _isTypeMenuOpen = false;
                      if (val == 'clear') {
                        _orderType = null;
                      } else {
                        _orderType = val;
                      }
                    });
                    _fetchOrders(refresh: true);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'NORMAL',
                      child: Row(
                        children: [
                          Expanded(child: Text(isAr ? 'عادي' : 'NORMAL')),
                          if (_orderType == 'NORMAL')
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.buttonBlueDark,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'AUTO',
                      child: Row(
                        children: [
                          Expanded(child: Text(isAr ? 'تلقائي' : 'AUTO')),
                          if (_orderType == 'AUTO')
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.buttonBlueDark,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                    if (_orderType != null)
                      PopupMenuItem(
                        value: 'clear',
                        child: Text(
                          isAr ? 'مسح الفلتر' : 'Clear',
                          style: const TextStyle(
                            color: AppColors.buttonBlueDark,
                          ),
                        ),
                      ),
                  ],
                  child: IgnorePointer(
                    child: FilterChip(
                      label: Text(
                        _orderType == 'NORMAL'
                            ? (isAr ? 'عادي' : 'Normal')
                            : _orderType == 'AUTO'
                            ? (isAr ? 'تلقائي' : 'Auto')
                            : (isAr ? 'النوع' : 'Type'),
                      ),
                      selected: _orderType != null || _isTypeMenuOpen,
                      onSelected: (_) {},
                      selectedColor: AppColors.buttonBlueDark,
                      showCheckmark: false,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: (_orderType != null || _isTypeMenuOpen)
                            ? Colors.transparent
                            : Colors.grey.shade300,
                      ),
                      labelStyle: TextStyle(
                        color: (_orderType != null || _isTypeMenuOpen)
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Date Range Filter
                FilterChip(
                  label: Text(
                    (_fromDate != null && _toDate != null)
                        ? '${DateFormat('MMM d').format(_fromDate!)} - ${DateFormat('MMM d').format(_toDate!)}'
                        : (isAr ? 'نطاق التاريخ' : 'Date Range'),
                  ),
                  selected: _fromDate != null && _toDate != null,
                  onSelected: (_) => _selectDateRange(context),
                  selectedColor: AppColors.buttonBlueDark,
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: (_fromDate != null && _toDate != null)
                        ? Colors.transparent
                        : Colors.grey.shade300,
                  ),
                  labelStyle: TextStyle(
                    color: (_fromDate != null && _toDate != null)
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                if (_fromDate != null && _toDate != null) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.black54,
                    ),
                    onPressed: _clearDateRange,
                    backgroundColor: Colors.grey.shade200,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isAr) {
    if (_orders.isEmpty) {
      return _buildEmptyState(
        _currentStatus == 'DELIVERED'
            ? (isAr ? 'تم التوصيل' : 'Delivered')
            : (isAr ? 'مؤكد' : 'Confirmed'),
        isAr,
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _orders.length + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _orders.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.buttonBlueDark),
            ),
          );
        }
        return _buildOrderCard(_orders[index], isAr);
      },
    );
  }

  Widget _buildOrderCard(NormalSubOrder order, bool isAr) {
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PastOrderDetailsPage(order: order),
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
                    if (order.product?.image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: (order.location?["image"] as String?) ?? "",

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
                              child: Icon(
                                order.location?['type']
                                            ?.toString()
                                            .toLowerCase() ==
                                        "orphanage"
                                    ? Icons.home
                                    : Icons.mosque,
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
                          color: AppColors.buttonBlueDark.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          order.location?['type']?.toString().toLowerCase() ==
                                  "orphanage"
                              ? Icons.home
                              : Icons.mosque,
                          color: AppColors.buttonBlueDark,
                          size: 32,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? (order.location?['nameAr'] ??
                                      order.location?['name'] ??
                                      'بدون اسم')
                                : (order.location?['name'] ?? 'No Name'),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (order.quantity != null && order.quantity! > 0)
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
                                      "${order.quantity} ${isAr ? order.product?.nameAr ?? 'طرود' : order.product?.name ?? 'Packages'}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.buttonBlueDark,
                                      ),
                                    ),
                                  ],
                                ),
                                Builder(
                                  builder: (context) {
                                    final dateString =
                                        order.deliveredAt ?? order.assignedDate;
                                    if (dateString == null) {
                                      return const SizedBox.shrink();
                                    }
                                    final date = DateTime.tryParse(
                                      dateString,
                                    )?.toLocal();
                                    if (date == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            order.status == 'DELIVERED'
                                                ? Icons.check_circle
                                                : Icons.calendar_today,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat(
                                              'MMM d, yyyy - h:mm a',
                                              Localizations.localeOf(context).languageCode,
                                            ).format(date),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
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

  Widget _buildEmptyState(String tabLabel, bool isAr) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
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
              isAr
                  ? 'لا توجد طلبات في قسم $tabLabel'
                  : 'No orders in $tabLabel',
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
      height: MediaQuery.of(context).size.height * 0.4,
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
                onPressed: () => _fetchOrders(refresh: true),
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
