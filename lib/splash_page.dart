import 'package:flutter/material.dart';
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
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final hasSession = AuthStorage.isLoggedIn;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                hasSession ? const HomePage() : const LoginPage(),
          ),
        );
      }
    });
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
