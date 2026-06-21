import 'package:flutter/material.dart';
import 'package:rahiq_driver/pages/autodelivery/auto_delivery_page.dart';
import 'package:rahiq_driver/pages/dashboard/dashboard_tab.dart';
import 'package:rahiq_driver/pages/orders/orders_page.dart';
import 'package:rahiq_driver/pages/profile/profile_tab.dart';
import 'package:rahiq_driver/pages/shared/custom_bottom_nav.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _pages = [
      const DashboardTab(),
      const OrdersPage(),
      const AutoDeliveryPage(),
      const ProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBody: true, // Allows body to extend behind the floating nav bar
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          CustomBottomNavItem(icon: Icons.dashboard, label: l10n.home),
          CustomBottomNavItem(icon: Icons.list_alt, label: l10n.orders),
          CustomBottomNavItem(icon: Icons.autorenew, label: l10n.autodelivery),
          CustomBottomNavItem(icon: Icons.person, label: l10n.profile),
        ],
      ),
    );
  }
}
