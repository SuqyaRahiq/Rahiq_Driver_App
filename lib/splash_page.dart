import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/pages/auth/login_page.dart';
import 'package:rahiq_driver/pages/home/home_page.dart';

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
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/splashbg.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            const Color(0xFF0F274A).withValues(alpha: 0.8),
            BlendMode.hardLight,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: Image.asset('assets/Raheeq_LOGO_transparent.apng'),
          ),
        ),
      ),
    );
  }
}
