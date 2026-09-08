import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rahiq_driver/common_widgets/custom_snackbar.dart';
import 'package:rahiq_driver/common_widgets/language_switch.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/api_exception.dart';
import 'package:rahiq_driver/services/notification_service.dart';
import 'package:rahiq_driver/data/api/driver/driver_auth_api.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/pages/home/home_page.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:rahiq_driver/utils/digits.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/water_loading.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  /// True while a login screen is on screen.
  ///
  /// [ApiClient] checks this before routing a dead session to login: pushing
  /// a second login page over this one destroys its state, taking whatever
  /// the driver has typed with it.
  static bool get isShowing => _LoginPageState._mountedCount > 0;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static int _mountedCount = 0;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final TapGestureRecognizer _termsTapRecognizer = TapGestureRecognizer();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final api = DriverAuthApi(ApiClient());

      String? fcmToken;
      try {
        // Bounded: on a device with a sick Play Services install this call can
        // stall for minutes, and login is not worth blocking on it — the
        // request falls back to a placeholder token below, and the real one is
        // pushed later via the device-token endpoint.
        fcmToken = await NotificationService().getToken().timeout(
          const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint('Failed to get FCM token: $e');
      }

      String? deviceId;
      try {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        if (Platform.isIOS) {
          final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor;
        } else if (Platform.isAndroid) {
          final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        }
      } catch (e) {
        debugPrint('Failed to get device info: $e');
      }

      final localeCode = mounted
          ? Localizations.localeOf(context).languageCode
          : 'en';
      final response = await api.login({
        "username": _usernameController.text.trim(),
        "deviceType": Platform.isIOS ? "IOS" : "ANDROID",
        "fcmToken": fcmToken ?? "dummy_fcm_token",
        "deviceId": deviceId ?? "dummy_device_id",
        "password": _passwordController.text.trim(),
        "locale": localeCode,
      });

      await AuthStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      if (response.driver != null) {
        await AuthStorage.saveUserData(response.driver!);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        final String errorMessage;
        if (e is! ApiException) {
          errorMessage = l10n.somethingWentWrong;
        } else if (e.isNetworkError) {
          errorMessage = l10n.connectionError;
        } else {
          // Server-sent message: wrong credentials, blocked account, etc.
          errorMessage = e.message;
        }
        CustomSnackbar.show(
          context: context,
          message: errorMessage,
          isError: true,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _mountedCount++;
  }

  @override
  void dispose() {
    _mountedCount--;
    _usernameController.dispose();
    _passwordController.dispose();
    _termsTapRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openTermsAndConditions() async {
    final url = Uri.parse("https://suqyarahiq.com/terms-and-conditions.html");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildTermsNotice(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
          children: [
            TextSpan(text: l10n.loginTermsPrefix),
            TextSpan(
              text: l10n.termsConditions,
              style: const TextStyle(
                color: AppColors.buttonBlueDark,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.buttonBlueDark,
                fontWeight: FontWeight.w600,
              ),
              recognizer: _termsTapRecognizer..onTap = _openTermsAndConditions,
            ),
            TextSpan(text: l10n.loginTermsSuffix),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.buttonBlueDark,
        shape: Border.all(width: 0, color: AppColors.buttonBlueDark),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.login,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 24),
            child: LanguageSwitchButton(isFromLogin: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.35,
                            width: MediaQuery.of(context).size.width,
                            decoration: const BoxDecoration(
                              color: AppColors.buttonBlueDark,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(40),
                                bottomRight: Radius.circular(40),
                              ),
                            ),
                            // Empty space instead of image
                            child: Center(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 180,
                                    width: 180,
                                    child: Image.asset(
                                      'assets/logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  SizedBox(height: 30),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.35 - 50,
                            left: 24,
                            right: 24,
                            bottom: 40,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.buttonBlueDark.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 50,
                                  offset: const Offset(0, 25),
                                  spreadRadius: -10,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Phone Input
                                  FormField<String>(
                                    validator: (_) {
                                      if (_usernameController.text
                                          .trim()
                                          .isEmpty) {
                                        return AppLocalizations.of(
                                          context,
                                        )!.pleaseEnterYourUsername;
                                      }
                                      return null;
                                    },
                                    builder: (state) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              border: Border.all(
                                                color: state.hasError
                                                    ? Colors.red.shade700
                                                    : AppColors.indicatorGrey,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.02),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.person_outline,
                                                  color: Colors.grey,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  height: 24,
                                                  width: 1,
                                                  color: Colors.grey[300],
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: TextField(
                                                    cursorColor: AppColors
                                                        .buttonBlueDark,
                                                    controller:
                                                        _usernameController,
                                                    keyboardType:
                                                        TextInputType.text,
                                                    inputFormatters: const [
                                                      LatinDigitsInputFormatter(),
                                                    ],
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.enterUsername,
                                                      hintStyle:
                                                          const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 14,
                                                          ),
                                                      border: InputBorder.none,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                    onChanged: (val) {
                                                      state.didChange(val);
                                                      if (state.hasError) {
                                                        state.validate();
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (state.hasError)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16,
                                                right: 16,
                                                top: 8,
                                              ),
                                              child: Text(
                                                state.errorText!,
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Password Input
                                  FormField<String>(
                                    validator: (_) {
                                      if (_passwordController.text
                                          .trim()
                                          .isEmpty) {
                                        return AppLocalizations.of(
                                          context,
                                        )!.pleaseEnterYourPassword;
                                      }
                                      return null;
                                    },
                                    builder: (state) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              border: Border.all(
                                                color: state.hasError
                                                    ? Colors.red.shade700
                                                    : AppColors.indicatorGrey,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.02),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.lock_outline,
                                                  color: Colors.grey,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  height: 24,
                                                  width: 1,
                                                  color: Colors.grey[300],
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: TextField(
                                                    cursorColor: AppColors
                                                        .buttonBlueDark,
                                                    controller:
                                                        _passwordController,
                                                    obscureText:
                                                        _obscurePassword,
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.enterPassword,
                                                      hintStyle:
                                                          const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 14,
                                                          ),
                                                      border: InputBorder.none,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                    onChanged: (val) {
                                                      state.didChange(val);
                                                      if (state.hasError) {
                                                        state.validate();
                                                      }
                                                    },
                                                  ),
                                                ),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: Icon(
                                                    _obscurePassword
                                                        ? Icons.visibility_off
                                                        : Icons.visibility,
                                                    color: Colors.grey,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscurePassword =
                                                          !_obscurePassword;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (state.hasError)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16,
                                                right: 16,
                                                top: 8,
                                              ),
                                              child: Text(
                                                state.errorText!,
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.buttonBlueDark,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            35,
                                          ),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? WaterLoadingIndicator(
                                              waveColor1:
                                                  AppColors.buttonBlueDark,
                                              size: 20,
                                            )
                                          : Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.login,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildTermsNotice(context),
          ],
        ),
      ),
    );
  }
}
