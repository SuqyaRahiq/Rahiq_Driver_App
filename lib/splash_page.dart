import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/pages/auth/login_page.dart';
import 'package:rahiq_driver/pages/home/home_page.dart';
import 'package:rahiq_driver/utils/colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // Show splash for at least 2 seconds
    await Future.delayed(const Duration(milliseconds: 3500));

    if (!mounted) return;

    if (!AuthStorage.isLoggedIn) {
      _goTo(const LoginPage());
      return;
    }

    // Validate the stored session by attempting a token refresh
    final isSessionValid = await ApiClient().refreshToken();
    if (!mounted) return;

    if (isSessionValid) {
      _goTo(const HomePage());
    } else {
      await AuthStorage.clearTokens();
      if (mounted) _goTo(const LoginPage());
    }
  }

  void _goTo(Widget page) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.buttonBlueDark,
      body: Center(
        child: Image.asset(
          'assets/Raheeq_LOGO_transparent.apng',
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
