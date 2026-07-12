import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rahiq_driver/utils/water_loading.dart';
import 'package:rahiq_driver/common_widgets/custom_app_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rahiq_driver/data/api/driver/driver_orders_api.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import '../../data/models/driver/mosque.dart';
import '../../data/models/driver/meqat_mosque.dart';
import '../../data/models/driver/orphanage.dart';
import '../../data/models/driver/place.dart';
import '../../utils/colors.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';

class SpecificMosquePage extends StatefulWidget {
  final String slug;
  final List<Place> initialSelections;
  final String? title;

  const SpecificMosquePage({
    super.key,
    this.slug = 'mosques',
    this.initialSelections = const [],
    this.title,
  });

  @override
  State<SpecificMosquePage> createState() => _SpecificMosquePageState();
}

class _SpecificMosquePageState extends State<SpecificMosquePage>
    with SingleTickerProviderStateMixin {
  final DriverOrdersApi _apiService = DriverOrdersApi(ApiClient());
  bool _isLoading = true;
  List<Place> _items = [];
  List<Place> _allMapItems = [];
  bool _isLoadingMapItems = true;
  List<Place> _filteredItems = [];

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  Map<String, dynamic>? _selectedCity;

  final List<Map<String, dynamic>> _cityFilters = [
    {'name': 'Makkah', 'nameAr': 'مكة المكرمة', 'lat': 21.3891, 'lng': 39.8579},
    {
      'name': 'Madina',
      'nameAr': 'المدينة المنورة',
      'lat': 24.5247,
      'lng': 39.5692,
    },
    {'name': 'Riyadh', 'nameAr': 'الرياض', 'lat': 24.7136, 'lng': 46.6753},
    {'name': 'Jeddah', 'nameAr': 'جدة', 'lat': 21.4858, 'lng': 39.1925},
    {'name': 'Sakaka', 'nameAr': 'سكاكا', 'lat': 29.9697, 'lng': 40.2064},
    {'name': 'Abha', 'nameAr': 'أبها', 'lat': 18.2164, 'lng': 42.5053},
    {'name': 'Taif', 'nameAr': 'الطائف', 'lat': 21.2643, 'lng': 40.4022},
  ];

  GoogleMapController? _mapController;
  final List<Place> _selectedItemsList = [];

  @override
  void initState() {
    super.initState();
    _selectedItemsList.addAll(widget.initialSelections);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_scrollListener);
    _initData();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    setState(() {
      _isLoadingMore = true;
    });
    _currentPage++;
    await _fetchItems(isLoadMore: true);
  }

  Position? _currentUserPosition;

  Future<void> _initData() async {
    _currentUserPosition = await _getUserLocation();
    _fetchAllMapItems();
    await _fetchItems();
  }

  Future<void> _fetchAllMapItems() async {
    try {
      dynamic response;
      if (widget.slug == 'orphanages') {
        response = await _apiService.getOrphanages(page: 1, limit: 1000);
      } else if (widget.slug == 'meqat_mosques') {
        response = await _apiService.getMiqatMosques(page: 1, limit: 1000);
      } else {
        response = await _apiService.getMosques(
          page: 1,
          limit: 1000,
          latitude: _currentUserPosition?.latitude,
          longitude: _currentUserPosition?.longitude,
        );
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            if (widget.slug == 'orphanages') {
              _allMapItems = data
                  .map((e) => Orphanage.fromJson(e as Map<String, dynamic>))
                  .toList();
            } else if (widget.slug == 'meqat_mosques') {
              _allMapItems = data
                  .map((e) => MeqatMosque.fromJson(e as Map<String, dynamic>))
                  .toList();
            } else {
              _allMapItems = data
                  .map((e) => Mosque.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
            _isLoadingMapItems = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingMapItems = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMapItems = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _items;
      } else {
        _filteredItems = _items.where((m) {
          final nameEn = m.name.toLowerCase();
          final nameAr = m.nameAr.toLowerCase();
          final address = m.address.toLowerCase();
          return nameEn.contains(query) ||
              nameAr.contains(query) ||
              address.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchItems({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
        _items.clear();
      });
    }

    try {
      dynamic response;
      if (widget.slug == 'orphanages') {
        response = await _apiService.getOrphanages(
          page: _currentPage,
          limit: 1000,
        );
      } else if (widget.slug == 'meqat_mosques') {
        response = await _apiService.getMiqatMosques(
          page: _currentPage,
          limit: 1000,
        );
      } else {
        response = await _apiService.getMosques(
          page: _currentPage,
          limit: 1000,
          latitude: _currentUserPosition?.latitude,
          longitude: _currentUserPosition?.longitude,
        );
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final Map<String, dynamic>? meta = response.data['meta'];

        setState(() {
          List<Place> newItems = [];
          if (widget.slug == 'orphanages') {
            newItems = data
                .map((e) => Orphanage.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (widget.slug == 'meqat_mosques') {
            newItems = data
                .map((e) => MeqatMosque.fromJson(e as Map<String, dynamic>))
                .toList();
          } else {
            newItems = data
                .map((e) => Mosque.fromJson(e as Map<String, dynamic>))
                .toList();
          }

          if (isLoadMore) {
            _items.addAll(newItems);
          } else {
            _items = newItems;
          }

          if (meta != null) {
            final int totalPages = meta['totalPages'] ?? 1;
            _hasMore = _currentPage < totalPages;
          } else {
            _hasMore = newItems.isNotEmpty;
          }

          _onSearchChanged(); // update _filteredItems
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    String title;
    String subtitle;
    String listTabText;

    if (widget.slug == 'orphanages') {
      title = widget.title ?? (AppLocalizations.of(context)!.choose_specific_orphanage);
      subtitle = AppLocalizations.of(context)!.select_an_orphanage_to_deliver_water_to;
      listTabText = AppLocalizations.of(context)!.list_of_orphanages;
    } else if (widget.slug == 'meqat_mosques') {
      title = widget.title ?? (AppLocalizations.of(context)!.choose_specific_meqat_mosque);
      subtitle = AppLocalizations.of(context)!.select_a_mosque_to_deliver_water_to;
      listTabText = AppLocalizations.of(context)!.list_of_meqat_mosques;
    } else {
      title = widget.title ?? (AppLocalizations.of(context)!.choose_specific_mosque);
      subtitle = AppLocalizations.of(context)!.select_a_mosque_to_deliver_water_to;
      listTabText = AppLocalizations.of(context)!.list_of_mosques;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CustomAppBar(
            hasBackgroundColor: true,
            isStartAligned: true,
            title: title,
            subtitle: subtitle,
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: AppColors.buttonBlueDark,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildDynamicHeader(isAr),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.buttonBlueDark,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.buttonBlueDark,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(text: listTabText),
                    Tab(text: AppLocalizations.of(context)!.choose_from_map),
                  ],
                ),
                Expanded(
                  child: _isLoading
                      ? _buildShimmerLoading()
                      : TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [_buildListTab(isAr), _buildMapTab(isAr)],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Position?> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getUserLocationAndMoveCamera() async {
    Position? position = await _getUserLocation();
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          12.0,
        ),
      );
    }
  }

  Widget _buildDynamicHeader(bool isAr) {
    if (_tabController.index == 0) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.indicatorGrey),
        ),
        child: TextField(
          cursorColor: AppColors.buttonBlueDark,

          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.slug == 'orphanages'
                ? (AppLocalizations.of(context)!.search_orphanages)
                : widget.slug == 'meqat_mosques'
                ? (AppLocalizations.of(context)!.search_meqat_mosques)
                : (AppLocalizations.of(context)!.search_mosques),
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.indicatorGrey),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            isExpanded: true,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(15),
            hint: Text(
              AppLocalizations.of(context)!.select_city,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            value: _selectedCity,
            items: _cityFilters.map((city) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: city,
                child: Text(
                  isAr ? city['nameAr'] : city['name'],
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCity = val;
              });
              if (val != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(val['lat'], val['lng']),
                    12.0,
                  ),
                );
              }
            },
          ),
        ),
      );
    }
  }

  Widget _buildListTab(bool isAr) {
    if (_filteredItems.isEmpty) {
      String emptyText;
      if (widget.slug == 'orphanages') {
        emptyText = "No orphanages found";
      } else if (widget.slug == 'meqat_mosques') {
        emptyText = "No meqat mosques found";
      } else {
        emptyText = "No mosques found";
      }
      return Center(child: Text(emptyText));
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) =>
          const Divider(height: 16, color: Colors.transparent),
      itemBuilder: (context, index) {
        if (index == _filteredItems.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: WaterLoadingIndicator(size: 30),
            ),
          );
        }
        final item = _filteredItems[index];

        bool isHighNeed = false;
        if (item is Orphanage) {
          isHighNeed = item.isHighNeed;
        }

        final isSelected = _selectedItemsList.any((m) => m.id == item.id);
        return Stack(
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              color: isSelected ? const Color(0xFFE8F4FA) : Colors.white,
              elevation: isSelected ? 5 : 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.buttonBlue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop(item);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.image != null && item.image!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: item.image!,
                        height: 140,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 140,
                          color: Colors.grey[200],
                          child: const Center(
                            child: WaterLoadingIndicator(size: 30),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 140,
                          color: Colors.grey[100],
                          child: Icon(
                            widget.slug == 'orphanages'
                                ? Icons.home
                                : Icons.mosque,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 140,
                        color: Colors.grey[100],
                        child: Icon(
                          widget.slug == 'orphanages'
                              ? Icons.home
                              : Icons.mosque,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.localizedName(isAr),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (item.address.isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isHighNeed)
              Positioned(
                top: 15,
                right: isAr ? null : 10,
                left: isAr ? 10 : null,
                child: Container(
                  margin: const EdgeInsetsDirectional.only(start: 8, end: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlue.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_outlined,
                        color: AppColors.buttonBlue,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? 'احتياج عالي' : 'High Need',
                        style: const TextStyle(
                          color: AppColors.buttonBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMapTab(bool isAr) {
    if (_isLoadingMapItems) {
      return const Center(child: WaterLoadingIndicator(size: 30));
    }

    final Set<Marker> markers = _allMapItems.map((item) {
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.latitude, item.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _selectedItemsList.any((m) => m.id == item.id)
              ? BitmapDescriptor.hueGreen
              : 207.0,
        ),
        infoWindow: InfoWindow(
          title: item.localizedName(isAr),
          snippet: item.address,
        ),
        onTap: () {
          Navigator.of(context).pop(item);
        },
      );
    }).toSet();

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(24.7136, 46.6753),
            zoom: 12,
          ),
          markers: markers,
          onMapCreated: (controller) {
            _mapController = controller;
            if (_selectedCity != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(_selectedCity!['lat'], _selectedCity!['lng']),
                  12.0,
                ),
              );
            } else {
              _getUserLocationAndMoveCamera();
            }
          },
          myLocationEnabled: true,
          myLocationButtonEnabled:
              false, // Disabled default to avoid overlap with our custom one
          zoomControlsEnabled: true,
        ),
        Positioned(
          bottom: 24,
          right: isAr ? null : 24,
          left: isAr ? 24 : null,
          child: FloatingActionButton(
            heroTag: 'customMyLocationBtn',
            backgroundColor: Colors.white,
            mini: false,
            onPressed: _getUserLocationAndMoveCamera,
            child: const Icon(
              Icons.my_location,
              color: AppColors.buttonBlueDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      key: const ValueKey('loader'),
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (context, index) =>
            const Divider(height: 16, color: Colors.transparent),
        itemBuilder: (context, index) {
          return Card(
            clipBehavior: Clip.antiAlias,
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.transparent, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 140, color: Colors.white),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 150,
                              height: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    height: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
