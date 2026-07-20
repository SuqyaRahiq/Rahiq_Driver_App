import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:rahiq_driver/utils/map_marker_icon.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/shimmer_loading.dart';
import 'package:rahiq_driver/data/models/driver/driver_dashboard_stats.dart';

class OrderListItem {
  final String id;
  final String title;
  final String? category;
  final int packages;
  final int orders;
  final DateTime? createdAt;
  final bool isAuto;
  final dynamic originalModel;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  OrderListItem({
    required this.id,
    required this.title,
    this.category,
    required this.packages,
    required this.orders,
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

  List<OrderListItem> _normalOrders = [];
  List<OrderListItem> _autoOrders = [];
  DriverDashboardStats? _dashboardStats;
  String? _dashboardETag;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  Timer? _refreshDebounceTimer;
  late List<_TabDef> _tabs;

  bool _isInit = true;

  // Map State
  bool _isMapMode = false;
  GoogleMapController? _mapController;
  BitmapDescriptor? _mapPinIcon;

  Future<void> _loadMapPinIcon() async {
    final mapPinIcon = await MapMarkerIcon.load();
    if (mounted && mapPinIcon != null) {
      setState(() => _mapPinIcon = mapPinIcon);
    }
  }

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
          icon:
              _mapPinIcon ?? BitmapDescriptor.defaultMarkerWithHue(198.0),
          infoWindow: InfoWindow(
            title: order.title,
            snippet:
                '${order.packages} ${AppLocalizations.of(context)!.products} | ${order.orders} ${AppLocalizations.of(context)!.orders}',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailsPage(
                    orderId: order.id,
                    name: order.originalModel.name ?? '',
                    nameAr: order.originalModel.nameAr ?? '',
                    orderType: order.originalModel.type,
                    isAutoOrder: order.isAuto,
                    latitude: order.latitude,
                    longitude: order.longitude,
                  ),
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

  void _focusMap() {
    if (_mapController == null) return;
    final normalOrders = _ordersForTab(0);
    for (final order in normalOrders) {
      final lat = order.latitude;
      final lng = order.longitude;
      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 10),
        );
        return;
      }
    }
    _goToMyLocation();
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

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        _currentTabIndex = _tabController.index;
        _fetchOrders();
      }
    });
    _ordersApi = DriverOrdersApi(ApiClient());
    _getPhoneNumber();
    _loadMapPinIcon();

    _fcmSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      if (!mounted || message.data['type'] != 'order_assigned') return;

      _refreshDebounceTimer?.cancel();
      _refreshDebounceTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _fetchOrdersSilently();
        }
      });
    });
  }

  Future<void> _fetchOrdersSilently() async {
    try {
      final newDashboardStats = await _ordersApi.getDashboardStats(
        eTag: _dashboardETag,
      );

      if (_tabController.index == 0) {
        final normalOrdersResponse = await _ordersApi.getNormalOrders(
          page: 1,
          limit: 30,
        );
        final normalOrders = normalOrdersResponse.items;
        final List<OrderListItem> combined = [];

        for (var order in normalOrders) {
          final title =
              (Directionality.of(context) == TextDirection.rtl
                  ? (order.nameAr ?? order.name)
                  : order.name) ??
              order.customerName ??
              AppLocalizations.of(context)!.unknownCustomer;

          combined.add(
            OrderListItem(
              id: order.id,
              title: title,
              category: order.type,
              packages: order.totalQuantity ?? 0,
              orders: order.totalSubOrders ?? 0,
              createdAt: order.createdAt,
              isAuto: false,
              originalModel: order,
              imageUrl: order.image,
              latitude: order.latitude,
              longitude: order.longitude,
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
            if (newDashboardStats != null) {
              _dashboardStats = newDashboardStats;
              _dashboardETag = newDashboardStats.eTag;
            }
            _normalOrders = combined;
            _normalOrdersPage = 1;
            _hasMoreNormalOrders = normalOrdersResponse.items.length == 30;
            _error = null;
          });
        }
      } else {
        final autoOrdersResponse = await _ordersApi.getAutoOrders(page: 1);
        final autoOrders = autoOrdersResponse.items;

        bool hasMore;
        if (autoOrdersResponse.meta != null) {
          hasMore =
              autoOrdersResponse.meta!.page <
              autoOrdersResponse.meta!.totalPages;
        } else {
          hasMore = false;
        }

        final List<OrderListItem> combined = [];

        for (var auto in autoOrders) {
          final autoTitle =
              (Directionality.of(context) == TextDirection.rtl &&
                  auto.nameAr.isNotEmpty)
              ? auto.nameAr
              : auto.name;
          combined.add(
            OrderListItem(
              id: auto.id,
              title: autoTitle,
              category: auto.type,
              orders: auto.totalSubOrders,
              packages: auto.totalQuantity,
              createdAt: null,
              isAuto: true,
              originalModel: auto,
              imageUrl: auto.image,
            ),
          );
        }

        if (mounted) {
          setState(() {
            if (newDashboardStats != null) {
              _dashboardStats = newDashboardStats;
              _dashboardETag = newDashboardStats.eTag;
            }
            _autoOrders = combined;
            _autoOrdersPage = 1;
            _hasMoreAutoOrders = hasMore;
            _error = null;
          });
        }
      }
    } catch (e) {
      // Swallow errors silently — this is a background refresh triggered by a
      // push notification, so we don't want to surface an error banner or
      // disrupt whatever the user is currently looking at.
      debugPrint('Silent order refresh failed: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fcmSubscription?.cancel();
    _refreshDebounceTimer?.cancel();
    super.dispose();
  }

  String _phoneNumber = '';
  int _autoOrdersPage = 1;
  bool _hasMoreAutoOrders = true;
  bool _isFetchingMoreAutoOrders = false;

  int _normalOrdersPage = 1;
  bool _hasMoreNormalOrders = true;
  bool _isFetchingMoreNormalOrders = false;

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
      setState(() {
        _isLoading = true;
        _error = null;
        _autoOrdersPage = 1;
        _hasMoreAutoOrders = true;
        _isFetchingMoreAutoOrders = false;
        _normalOrdersPage = 1;
        _hasMoreNormalOrders = true;
        _isFetchingMoreNormalOrders = false;
      });

      final newDashboardStats = await _ordersApi.getDashboardStats(
        eTag: _dashboardETag,
      );

      if (_tabController.index == 0) {
        final normalOrdersResponse = await _ordersApi.getNormalOrders(
          page: 1,
          limit: 30,
        );
        final normalOrders = normalOrdersResponse.items;
        final List<OrderListItem> combined = [];

        for (var order in normalOrders) {
          final title =
              (Directionality.of(context) == TextDirection.rtl
                  ? (order.nameAr ?? order.name)
                  : order.name) ??
              order.customerName ??
              AppLocalizations.of(context)!.unknownCustomer;

          combined.add(
            OrderListItem(
              id: order.id,
              title: title,
              category: order.type,
              packages: order.totalQuantity ?? 0,
              orders: order.totalSubOrders ?? 0,
              createdAt: order.createdAt,
              isAuto: false,
              originalModel: order,
              imageUrl: order.image,
              latitude: order.latitude,
              longitude: order.longitude,
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
            if (newDashboardStats != null) {
              _dashboardStats = newDashboardStats;
              _dashboardETag = newDashboardStats.eTag;
            }
            _normalOrders = combined;
            _hasMoreNormalOrders = normalOrdersResponse.items.length == 30;
            _isLoading = false;
          });
        }
      } else {
        final autoOrdersResponse = await _ordersApi.getAutoOrders(
          page: _autoOrdersPage,
        );
        final autoOrders = autoOrdersResponse.items;

        if (autoOrdersResponse.meta != null) {
          _hasMoreAutoOrders =
              autoOrdersResponse.meta!.page <
              autoOrdersResponse.meta!.totalPages;
        } else {
          _hasMoreAutoOrders = false;
        }

        final List<OrderListItem> combined = [];

        for (var auto in autoOrders) {
          final autoTitle =
              (Directionality.of(context) == TextDirection.rtl &&
                  auto.nameAr.isNotEmpty)
              ? auto.nameAr
              : auto.name;
          combined.add(
            OrderListItem(
              id: auto.id,
              title: autoTitle,
              category: auto.type,
              orders: auto.totalSubOrders,
              packages: auto.totalQuantity,
              createdAt: null,
              isAuto: true,
              originalModel: auto,
              imageUrl: auto.image,
            ),
          );
        }

        if (mounted) {
          setState(() {
            if (newDashboardStats != null) {
              _dashboardStats = newDashboardStats;
              _dashboardETag = newDashboardStats.eTag;
            }
            _autoOrders = combined;
            _isLoading = false;
          });
        }
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

  Future<void> _fetchMoreAutoOrders() async {
    if (_isFetchingMoreAutoOrders || !_hasMoreAutoOrders) return;

    setState(() {
      _isFetchingMoreAutoOrders = true;
    });

    try {
      final nextPage = _autoOrdersPage + 1;
      final autoOrdersResponse = await _ordersApi.getAutoOrders(page: nextPage);
      final newAutoOrders = autoOrdersResponse.items;

      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final List<OrderListItem> newItems = [];

      for (var auto in newAutoOrders) {
        final autoTitle = (isArabic && auto.nameAr.isNotEmpty)
            ? auto.nameAr
            : auto.name;
        newItems.add(
          OrderListItem(
            id: auto.id,
            title: autoTitle,
            category: auto.type,
            orders: auto.totalSubOrders,
            packages: auto.totalQuantity,
            createdAt: null,
            isAuto: true,
            originalModel: auto,
            imageUrl: auto.image,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _autoOrdersPage = nextPage;
          _autoOrders.addAll(newItems);
          if (newItems.isEmpty || newItems.length < 30) {
            _hasMoreAutoOrders = false;
          }
          _isFetchingMoreAutoOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingMoreAutoOrders = false;
        });
      }
    }
  }

  Future<void> _fetchMoreNormalOrders() async {
    if (_isFetchingMoreNormalOrders || !_hasMoreNormalOrders) return;

    setState(() {
      _isFetchingMoreNormalOrders = true;
    });

    try {
      final nextPage = _normalOrdersPage + 1;
      final normalOrdersResponse = await _ordersApi.getNormalOrders(
        page: nextPage,
        limit: 30,
      );
      final newNormalOrders = normalOrdersResponse.items;

      final List<OrderListItem> newItems = [];

      for (var order in newNormalOrders) {
        final title =
            (Directionality.of(context) == TextDirection.rtl
                ? (order.nameAr ?? order.name)
                : order.name) ??
            order.customerName ??
            AppLocalizations.of(context)!.unknownCustomer;

        newItems.add(
          OrderListItem(
            id: order.id,
            title: title,
            category: order.type,
            packages: order.totalQuantity ?? 0,
            orders: order.totalSubOrders ?? 0,
            createdAt: order.createdAt,
            isAuto: false,
            originalModel: order,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _normalOrdersPage = nextPage;
          _normalOrders.addAll(newItems);
          if (newItems.isEmpty || newItems.length < 30) {
            _hasMoreNormalOrders = false;
          }
          _isFetchingMoreNormalOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingMoreNormalOrders = false;
        });
      }
    }
  }

  List<OrderListItem> _ordersForTab(int tabIndex) {
    if (tabIndex == 0) {
      return _normalOrders;
    } else {
      return _autoOrders;
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
          _fetchOrders();
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
                              _focusMap();
                            },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Transform.flip(
                          flipX:
                              Directionality.of(context) == TextDirection.rtl,
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
                    _fetchOrders();
                  },
                  icon: const Icon(Icons.list_alt),
                  label: Text(l10n.orders),
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
            _tabController.index == 0
                ? _statCardSection(
                    _dashboardStats?.normalAssignedPackagesCount ?? 0,
                    _dashboardStats?.normalAssignedCount ?? 0,
                    _isLoading,
                    _isMapMode,
                  )
                : _statCardSection(
                    _dashboardStats?.autoAssignedPackagesCount ?? 0,
                    _dashboardStats?.autoAssignedCount ?? 0,
                    _isLoading,
                    _isMapMode,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _statCardSection(
    int count1,
    int count2,
    bool isLoading,
    bool isMapMode,
  ) {
    Widget content = Row(
      spacing: 16,
      children: [
        Expanded(
          child: Card(
            surfaceTintColor: AppColors.buttonBlueDark.withValues(alpha: 0.5),
            margin: const EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isMapMode ? AppColors.buttonBlueDark : Colors.white,
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                spacing: 6,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: Icon(
                      Symbols.package_2,
                      size: 40,
                      color: isMapMode
                          ? Colors.white
                          : AppColors.buttonBlueDark,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.quantity,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isMapMode
                          ? Colors.white
                          : AppColors.buttonBlueDark,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "$count1 ${AppLocalizations.of(context)!.quantity}",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isMapMode
                          ? Colors.white
                          : AppColors.buttonBlueDark,
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
            surfaceTintColor: AppColors.buttonBlueDark.withValues(alpha: 0.5),
            margin: const EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isMapMode ? AppColors.buttonBlueDark : Colors.white,
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                spacing: 6,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: Icon(
                      Symbols.delivery_truck_speed,
                      size: 40,
                      color: isMapMode
                          ? Colors.white
                          : AppColors.buttonBlueDark,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.orders,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isMapMode
                          ? Colors.white
                          : AppColors.buttonBlueDark,

                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "$count2 ${AppLocalizations.of(context)!.orders}",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isMapMode
                          ? Colors.white
                          : AppColors.buttonBlueDark,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (isLoading) {
      Widget buildShimmerCard() {
        return Expanded(
          child: Card(
            margin: const EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Container(
                      width: 70,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 90,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      content = Row(
        spacing: 16,
        children: [buildShimmerCard(), buildShimmerCard()],
      );
    }

    return SafeArea(
      bottom: false,
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              top: _isMapMode ? 20 : _cardsTop,
              left: 16,
              right: 16,
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(int tabIndex) {
    final orders = _ordersForTab(tabIndex);
    if (orders.isEmpty) return _buildEmptyState(_tabs[tabIndex].label);

    final isAutoTab = tabIndex == 1;
    final isFetchingMore = isAutoTab
        ? _isFetchingMoreAutoOrders
        : _isFetchingMoreNormalOrders;
    final hasMore = isAutoTab ? _hasMoreAutoOrders : _hasMoreNormalOrders;

    final itemCount = orders.length + (isFetchingMore ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoading &&
            !isFetchingMore &&
            hasMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          if (isAutoTab) {
            _fetchMoreAutoOrders();
          } else {
            _fetchMoreNormalOrders();
          }
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (isFetchingMore && index == orders.length) {
            return const ListShimmerLoader(itemCount: 4);
          }
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderListItem order) {
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
              builder: (_) => OrderDetailsPage(
                orderId: order.id,
                name: order.originalModel.name ?? '',
                nameAr: order.originalModel.nameAr ?? '',
                orderType: order.originalModel.type,
                isAutoOrder: order.isAuto,
                latitude: order.latitude,
                longitude: order.longitude,
              ),
            ),
          ).then((_) => _fetchOrders());
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
                              child: Icon(
                                order.category?.toLowerCase() == "orphanage" ||
                                        order.category?.toLowerCase() ==
                                            "orphanages"
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
                          order.category?.toLowerCase() == "orphanage" ||
                                  order.category?.toLowerCase() == "orphanages"
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
                            order.title,
                            maxLines: order.isAuto ? 1 : null,
                            overflow: order.isAuto
                                ? TextOverflow.ellipsis
                                : null,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),

                          if (order.packages != 0 && order.orders != 0) ...[
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
                                      "${order.packages} ${AppLocalizations.of(context)!.packages}",
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
                                      "${order.orders} ${AppLocalizations.of(context)!.orders}",
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchOrders,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(AppLocalizations.of(context)!.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBlueDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
