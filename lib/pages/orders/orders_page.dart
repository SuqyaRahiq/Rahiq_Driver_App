import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_orders_api.dart';
import 'package:rahiq_driver/pages/orders/order_details_page.dart';
import 'package:rahiq_driver/pages/orders/auto_order_details_page.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/shimmer_loading.dart';

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
  final double? latitude;
  final double? longitude;

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
    this.latitude,
    this.longitude,
  });
}

class OrdersPage extends StatefulWidget {
  final ValueChanged<bool>? onMapModeChanged;

  const OrdersPage({super.key, this.onMapModeChanged});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late DriverOrdersApi _ordersApi;
  late TabController _tabController;

  final GlobalKey _placeholderKey = GlobalKey();
  double _cardsTop = 165.0;

  List<OrderListItem> _allOrders = [];
  bool _isLoading = true;
  String? _error;

  late List<_TabDef> _tabs;

  bool _isInit = true;

  // Map State
  bool _isMapMode = false;
  GoogleMapController? _mapController;

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};
    final normalOrders = _ordersForTab(0);
    for (final order in normalOrders) {
      final lat = order.latitude;
      final lng = order.longitude;
      if (lat == null || lng == null || lat == 0.0 || lng == 0.0) continue;

      markers.add(
        Marker(
          markerId: MarkerId(order.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: order.title,
            snippet: order.address,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailsPage(order: order.originalModel),
                ),
              ).then((_) => _fetchOrders());
            },
          ),
        ),
      );
    }
    return markers;
  }

  LatLng _initialTarget() {
    final normalOrders = _ordersForTab(0);
    // Find the first order with valid coords, else default to Riyadh
    for (final order in normalOrders) {
      final lat = order.latitude;
      final lng = order.longitude;
      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        return LatLng(lat, lng);
      }
    }
    return const LatLng(24.7136, 46.6753); // Riyadh fallback
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        14.0,
      ),
    );
  }

  void _fitAllMarkers() {
    final markers = _buildMarkers();
    if (markers.isEmpty || _mapController == null) return;
    if (markers.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(markers.first.position, 14.0),
      );
      return;
    }

    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final m in markers) {
      if (m.position.latitude < minLat) minLat = m.position.latitude;
      if (m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (m.position.longitude < minLng) minLng = m.position.longitude;
      if (m.position.longitude > maxLng) maxLng = m.position.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

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
    _getPhoneNumber();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _phoneNumber = '';

  Future<void> _getPhoneNumber() async {
    final driverProfile = AuthStorage.getUserData();

    if (driverProfile != null) {
      setState(() {
        _phoneNumber = driverProfile.countryCode + driverProfile.phoneNumber;
      });
    }
  }

  Future<void> _fetchOrders() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final normalOrdersResponse = await _ordersApi.getNormalOrders();
      final normalOrders = normalOrdersResponse.items;
      final autoOrdersResponse = await _ordersApi.getAutoOrders();
      final autoOrders = autoOrdersResponse.items;

      final List<OrderListItem> combined = [];

      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      for (var order in normalOrders) {
        final title =
            (isArabic ? (order.nameAr ?? order.name) : order.name) ??
            order.customerName ??
            AppLocalizations.of(context)!.unknownCustomer;

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
            address =
                '${order.totalQuantity} ${AppLocalizations.of(context)!.packages} • $address';
          } else {
            address =
                '${order.totalQuantity} ${AppLocalizations.of(context)!.packages}';
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
            latitude: order.latitude,
            longitude: order.longitude,
          ),
        );
      }

      for (var auto in autoOrders) {
        final autoTitle = (isArabic && auto.nameAr.isNotEmpty)
            ? auto.nameAr
            : auto.name;
        combined.add(
          OrderListItem(
            id: auto.id,
            title: autoTitle,
            subtitle: l10n.autoOrderNumber(auto.id),
            address:
                '${auto.totalQuantity} ${AppLocalizations.of(context)!.packages}',
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

  void _updateCardsTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_placeholderKey.currentContext != null) {
        final RenderBox renderBox =
            _placeholderKey.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final safeAreaTop = MediaQuery.of(context).padding.top;
        final newTop = position.dy - safeAreaTop;
        if ((_cardsTop - newTop).abs() > 0.5) {
          setState(() {
            _cardsTop = newTop;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _updateCardsTop();
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final markers = _buildMarkers();

    return PopScope(
      canPop: !_isMapMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (_isMapMode) {
          setState(() {
            _isMapMode = false;
          });
          widget.onMapModeChanged?.call(false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // ── 1. Map Layer (Always built, in background) ──
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialTarget(),
                  zoom: 12,
                ),
                markers: markers,

                onMapCreated: (controller) {
                  _mapController = controller;
                  Future.delayed(
                    const Duration(milliseconds: 500),
                    _fitAllMarkers,
                  );
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),

            // ── 2. List Layer (Fades out in Map Mode) ──
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: _isMapMode ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: _isMapMode,
                  child: RefreshIndicator(
                    onRefresh: _fetchOrders,
                    color: AppColors.buttonBlueDark,
                    child: Column(
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          color: AppColors.buttonBlueDark,
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                16,
                                16,
                                16,
                                12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.welcome,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        textDirection: TextDirection.ltr,
                                        _phoneNumber,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Invisible placeholder for the Map Icon Button (to keep height)
                                  const Opacity(
                                    opacity: 0,
                                    child: IconButton.filled(
                                      onPressed: null,
                                      icon: Icon(Icons.map_rounded),
                                      iconSize: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Rounded body
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 60,
                                color: AppColors.buttonBlueDark,
                              ),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Material(
                                        elevation: 1,
                                        borderRadius: BorderRadius.circular(25),
                                        color: Colors.white,
                                        child: Container(
                                          height: 60,
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                          ),
                                          child: TabBar(
                                            splashFactory:
                                                NoSplash.splashFactory,
                                            splashBorderRadius:
                                                BorderRadius.circular(25),
                                            controller: _tabController,
                                            indicatorSize:
                                                TabBarIndicatorSize.tab,
                                            dividerColor: Colors.transparent,
                                            indicator: BoxDecoration(
                                              color: AppColors.buttonBlueDark,
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                            labelColor: Colors.white,
                                            unselectedLabelColor:
                                                Colors.grey[600],
                                            labelStyle: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            unselectedLabelStyle:
                                                const TextStyle(
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
                                    ),
                                    const SizedBox(height: 16),
                                    // Placeholder for Cards (to maintain scroll height)
                                    Opacity(
                                      key: _placeholderKey,
                                      opacity: 0,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: SizedBox(
                                          height: 110,
                                        ), // approx height of cards
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: _isLoading
                                          ? const SingleChildScrollView(
                                              physics:
                                                  AlwaysScrollableScrollPhysics(),
                                              child: ListShimmerLoader(
                                                itemCount: 10,
                                              ),
                                            )
                                          : _error != null
                                          ? SingleChildScrollView(
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(),
                                              child: _buildErrorState(),
                                            )
                                          : AnimatedBuilder(
                                              animation: _tabController,
                                              builder: (context, _) {
                                                return _buildTabContent(
                                                  _tabController.index,
                                                );
                                              },
                                            ),
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
                ),
              ),
            ),

            // ── 3. Action Buttons (Morphing FAB & Show Menu) ──
            if (_tabController.index == 0) ...[
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                top: _isMapMode
                    ? MediaQuery.of(context).size.height - 80
                    : MediaQuery.of(context).padding.top + 16,
                right: isAr ? null : 16,
                left: isAr ? 16 : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  width: _isMapMode ? 56 : 48,
                  height: _isMapMode ? 56 : 48,
                  decoration: BoxDecoration(
                    color: _isMapMode ? AppColors.buttonBlueDark : Colors.white,
                    borderRadius: BorderRadius.circular(_isMapMode ? 16 : 24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(_isMapMode ? 16 : 24),
                      onTap: _isMapMode
                          ? _goToMyLocation
                          : () {
                              setState(() => _isMapMode = true);
                              widget.onMapModeChanged?.call(true);
                            },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          _isMapMode
                              ? Icons.my_location_rounded
                              : Icons.map_rounded,
                          key: ValueKey(_isMapMode),
                          color: _isMapMode
                              ? Colors.white
                              : AppColors.buttonBlueDark,
                          size: _isMapMode ? 24 : 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            if (_isMapMode)
              Positioned(
                top: MediaQuery.of(context).padding.top + 150, // Below cards
                right: isAr ? null : 16,
                left: isAr ? 16 : null,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() => _isMapMode = false);
                    widget.onMapModeChanged?.call(false);
                  },
                  icon: const Icon(Icons.menu_rounded),
                  label: Text(l10n.showMenu),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.buttonBlueDark,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

            // ── 4. Floating Header Elements (Cards) ──
            // Since the cards need to stick to the list while scrolling in List Mode,
            // we use a neat trick: we align them based on the screen, but when not in map mode,
            // they sit exactly where the placeholder is.
            // Since we want them to stay in view when animating, we will make them sticky at the top always.
            SafeArea(
              bottom: false,
              child: IgnorePointer(
                ignoring: false,
                child: Stack(
                  children: [
                    // Order Count Cards
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      top: _isMapMode
                          ? 20
                          : _cardsTop, // 20 in Map, dynamic measured top in List
                      left: 16,
                      right: 16,
                      child: Row(
                        spacing: 16,
                        children: [
                          Expanded(
                            child: Card(
                              margin: const EdgeInsets.all(0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Colors.white,
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  spacing: 6,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Symbols.package_2,
                                      size: 40,
                                      color: AppColors.buttonBlueDark,
                                    ),
                                    Text(
                                      l10n.orders,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "20 ${l10n.packages}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              margin: const EdgeInsets.all(0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Colors.white,
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  spacing: 6,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Symbols.package_2,
                                      size: 40,
                                      color: AppColors.buttonBlueDark,
                                    ),
                                    Text(
                                      l10n.orders,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "20 ${l10n.packages}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(int tabIndex) {
    final orders = _ordersForTab(tabIndex);
    if (orders.isEmpty) return _buildEmptyState(_tabs[tabIndex].label);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }

  Widget _buildOrderCard(OrderListItem order) {
    // final statusColor = _getStatusColor(order.status);

    return Material(
      color: Colors.white,
      elevation: 1,

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
            ).then((_) => _fetchOrders());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsPage(order: order.originalModel),
              ),
            ).then((_) => _fetchOrders());
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
}

class _TabDef {
  final String label;
  final List<String> statuses;
  const _TabDef(this.label, this.statuses);
}
