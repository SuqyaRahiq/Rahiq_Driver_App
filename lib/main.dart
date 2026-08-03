import 'dart:developer';
import 'package:flutter/services.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/services/freshchat_service.dart';
import 'package:rahiq_driver/splash_page.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rahiq_driver/services/notification_service.dart';
// import 'firebase_options.dart'; // Uncomment after running flutterfire configure

import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rahiq_driver/utils/colors.dart';

late ValueNotifier<Locale> localeNotifier;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await dotenv.load(fileName: ".env");
  await AuthStorage.init();
  await initializeDateFormatting();

  // Load saved language or default to English
  final savedLanguage = AuthStorage.getLanguage();
  localeNotifier = ValueNotifier(Locale(savedLanguage));

  try {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
    );
    await Permission.notification.request();
    await NotificationService().init();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  final freshchatAppId = dotenv.env['FRESHCHAT_APP_ID'];
  final freshchatAppKey = dotenv.env['FRESHCHAT_APP_KEY'];
  final freshchatDomain = dotenv.env['FRESHCHAT_DOMAIN'];

  if (freshchatAppId != null &&
      freshchatAppId.isNotEmpty &&
      freshchatAppKey != null &&
      freshchatAppKey.isNotEmpty &&
      freshchatDomain != null &&
      freshchatDomain.isNotEmpty) {
    Freshchat.init(freshchatAppId, freshchatAppKey, freshchatDomain);

    // Initialize Freshchat service listeners
    FreshchatService.init();

    // Register this device's FCM token with Freshchat so it can deliver
    // push notifications for chat messages.
    await FreshchatService.registerPushToken();

    // Set user info if session exists
    try {
      final driver = AuthStorage.getUserData();
      if (driver != null) {
        await FreshchatService.identifyUser(driver);
      }
    } catch (e) {
      debugPrint('Failed to set Freshchat user: $e');
    }
  }

  runApp(const MyApp());
}

class MyScrollBehavior extends MaterialScrollBehavior {
  const MyScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, child) {
        final double bottomPadding = MediaQueryData.fromView(
          View.of(context),
        ).padding.bottom;
        final bool isThickNavBar = bottomPadding > 24.0;
        log('isThickNavBar: $isThickNavBar');
        log('bottomPadding: $bottomPadding');

        return SafeArea(
          minimum: EdgeInsets.zero,
          bottom: Platform.isAndroid ? isThickNavBar : false,
          top: false,
          child: MaterialApp(
            title: 'Rahiq Driver',
            navigatorKey: navigatorKey,
            builder: (context, child) {
              final mediaQueryData = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQueryData.copyWith(
                  textScaler: _ArabicTextScaler(
                    mediaQueryData.textScaler,
                    locale.languageCode == 'ar',
                  ),
                ),
                child: child!,
              );
            },
            locale: locale,
            debugShowCheckedModeBanner: false,
            scrollBehavior: const MyScrollBehavior(),
            theme: () {
              var theme = ThemeData(
                fontFamily: GoogleFonts.manrope().fontFamily,
                fontFamilyFallback: const ['SaudiRiyal', 'SF Pro'],
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
                useMaterial3: true,
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: AppColors.buttonBlueDark,
                  selectionHandleColor: AppColors.buttonBlueDark,
                  selectionColor: AppColors.buttonBlueDark.withValues(
                    alpha: 0.3,
                  ),
                ),
              );
              return theme;
            }(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
            home: const SplashPage(),
          ),
        );
      },
    );
  }
}

class _ArabicTextScaler extends TextScaler {
  final TextScaler baseScaler;
  final bool isArabic;

  const _ArabicTextScaler(this.baseScaler, this.isArabic);

  @override
  double scale(double fontSize) {
    double scaled = baseScaler.scale(fontSize);
    return isArabic ? scaled + 1.0 : scaled;
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => baseScaler.textScaleFactor;
}
