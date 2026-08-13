import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/models/driver/driver_profile.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/pages/autodelivery/auto_delivery_page.dart';
import 'package:rahiq_driver/pages/orders/orders_page.dart';
import 'package:rahiq_driver/pages/profile/profile_tab.dart';
import 'package:rahiq_driver/pages/shared/custom_bottom_nav.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';

/// Tabs the home page can open on. The auto delivery tab only exists for
/// drivers with auto delivery enabled — asking for it otherwise falls back
/// to orders.
enum HomeTab { orders, autoDelivery, profile }

class HomePage extends StatefulWidget {
  final HomeTab initialTab;

  const HomePage({super.key, this.initialTab = HomeTab.orders});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _hideNavBar = false;
  DriverProfile? driver;
  late List<Widget> _pages;
  late List<HomeTab> _tabs;
  bool _initialTabApplied = false;
  @override
  void initState() {
    driver = AuthStorage.getUserData();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabs = [
      HomeTab.orders,
      if (driver!.isAutoDeliveryEnabled) HomeTab.autoDelivery,
      HomeTab.profile,
    ];
    _pages = [
      OrdersPage(
        onMapModeChanged: (isMapMode) {
          setState(() {
            _hideNavBar = isMapMode;
          });
        },
      ),
      if (driver!.isAutoDeliveryEnabled) ...{const AutoDeliveryPage()},

      const ProfileTab(),
    ];

    if (!_initialTabApplied) {
      _initialTabApplied = true;
      final index = _tabs.indexOf(widget.initialTab);
      if (index != -1) _currentIndex = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _currentIndex = 0;
        });
      },
      child: Scaffold(
        extendBody: true, // Allows body to extend behind the floating nav bar
        body: _pages[_currentIndex],
        bottomNavigationBar: AnimatedSlide(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          offset: _hideNavBar ? const Offset(0, 1.5) : Offset.zero,
          child: CustomBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              CustomBottomNavItem(icon: Icons.list_alt, label: l10n.orders),
              if (driver!.isAutoDeliveryEnabled) ...{
                CustomBottomNavItem(
                  icon: Icons.autorenew,
                  label: l10n.autodelivery,
                ),
              },

              CustomBottomNavItem(icon: Icons.person, label: l10n.profile),
            ],
          ),
        ),
      ),
    );
  }
}
