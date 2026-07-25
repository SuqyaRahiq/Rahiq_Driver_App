import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_auth_api.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/pages/auth/login_page.dart';
import 'package:rahiq_driver/pages/home/home_page.dart';
import 'package:rahiq_driver/utils/colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  /// Shown when we couldn't verify the session because of a network/server
  /// error. Lets the user retry instead of being logged out.
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // Show splash for at least 3.5 seconds
    await Future.delayed(const Duration(milliseconds: 3500));

    if (!mounted) return;

    if (mounted) {
      setState(() => _showRetry = false);
    }

    if (!AuthStorage.isLoggedIn) {
      _goTo(const LoginPage());
      return;
    }

    // Validate the stored session by attempting a token refresh.
    // refreshToken() now throws on network/server errors (instead of
    // returning false), so we can distinguish "no internet" from
    // "refresh token is genuinely invalid".
    bool isSessionValid;
    try {
      isSessionValid = await ApiClient().refreshToken();
    } catch (_) {
      // Network/server error — show retry instead of logging out.
      if (mounted) setState(() => _showRetry = true);
      return;
    }

    if (!mounted) return;

    if (isSessionValid) {
      await _refreshAndStoreDriverProfile();
      if (!mounted) return;
      _goTo(const HomePage());
    } else {
      await AuthStorage.clearTokens();
      if (mounted) _goTo(const LoginPage());
    }
  }

  Future<void> _refreshAndStoreDriverProfile() async {
    try {
      final profile = await DriverAuthApi(ApiClient()).getProfile();
      await AuthStorage.saveUserData(profile);
    } catch (_) {
      // Keep the last cached profile when the refresh cannot be completed.
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
        child: _showRetry
            ? _buildRetryState()
            : Image.asset(
                'assets/Raheeq_LOGO_transparent.apng',
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.contain,
              ),
      ),
    );
  }

  Widget _buildRetryState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off, color: Colors.white, size: 48),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.connectionError,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _navigateAfterSplash,
          child: Text(AppLocalizations.of(context)!.retryButton),
        ),
      ],
    );
  }
}
