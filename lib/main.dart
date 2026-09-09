import 'dart:async';
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
import 'package:rahiq_driver/utils/colors.dart';

late ValueNotifier<Locale> localeNotifier;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// True while [SplashPage] is on screen. The app backdrop below - the strip the
// bottom [SafeArea] leaves on Android, and the system navigation bar painted
// over it - follows the splash's own background rather than sitting as a white
// band under the splash art. Every screen after the splash is white, bar the
// camera below.
// [SplashPage] clears this from its dispose, so the backdrop stays with the
// splash for the whole replace transition instead of turning white under it.
final ValueNotifier<bool> isSplashVisible = ValueNotifier<bool>(true);

// True while [CustomCameraScreen] is on screen, in photo mode and video mode
// alike. That screen is full-bleed black, so the backdrop above goes black
// with it rather than leaving a white band under the viewfinder.
// [CustomCameraScreen] clears this from its dispose.
final ValueNotifier<bool> isCameraVisible = ValueNotifier<bool>(false);

// True while [OrderDeliveredPage] is on screen. It fills the screen with
// AppColors.buttonBlueDark, the same colour the splash uses, so the backdrop
// follows it for the same reason. [OrderDeliveredPage] clears this from its
// dispose.
final ValueNotifier<bool> isOrderDeliveredVisible = ValueNotifier<bool>(false);

// The whole app renders at w700. Two things are needed and both are load-
// bearing:
//
//  - these families, each holding exactly one face (see pubspec.yaml). A
//    single-face family renders every requested [FontWeight] with that face,
//    which is what stops the inline w500/w600 styles scattered through the app
//    from opting out. Pointing at a normal multi-weight family would undo it.
//  - [MediaQueryData.boldText] below, so text that falls through to the
//    fallback fonts is asked for bold as well.
//
// Manrope carries no Arabic glyphs, so Arabic needs its own bundled face; left
// to the OS fallback there was no bold face available and Arabic could never
// bolden.
const String _latinFontFamily = 'ManropeBold';
const String _arabicFontFamily = 'NotoNaskhArabicBold';

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

    // Allow a brief moment for native SDK init to complete
    await Future.delayed(const Duration(milliseconds: 150));

    // Register this device's push token with Freshchat so it can deliver
    // push notifications for chat messages.
    await FreshchatService.registerPushToken();

    // Set user info if session exists. Not awaited: the first frame must not
    // wait on the chat SDK answering, and identifyUser logs its own failures.
    try {
      final driver = AuthStorage.getUserData();
      if (driver != null) {
        unawaited(FreshchatService.identifyUser(driver));
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        localeNotifier,
        isSplashVisible,
        isCameraVisible,
        isOrderDeliveredVisible,
      ]),
      builder: (context, child) {
        final Locale locale = localeNotifier.value;
      
       

        final double bottomPadding = MediaQueryData.fromView(
          View.of(context),
        ).padding.bottom;
        final bool isThickNavBar = bottomPadding >= 24.0;
        log('isThickNavBar: $isThickNavBar');
        log('bottomPadding: $bottomPadding');

       

        return SafeArea(
          bottom: Platform.isAndroid ? true : false,
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
                  boldText: true,
                ),
                child: child!,
              );
            },
            locale: locale,
            debugShowCheckedModeBanner: false,
            scrollBehavior: const MyScrollBehavior(),
            theme: ThemeData(
              fontFamily: _latinFontFamily,
              // Arabic goes last so the riyal glyph and the existing Latin
              // fallback keep resolving exactly as they did before; Arabic
              // letters appear in none of those, so they fall through.
              fontFamilyFallback: const [
                'SaudiRiyal',
                'SF Pro',
                _arabicFontFamily,
              ],
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              useMaterial3: true,
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: AppColors.buttonBlueDark,
                selectionHandleColor: AppColors.buttonBlueDark,
                selectionColor: AppColors.buttonBlueDark.withValues(alpha: 0.3),
              ),
            ),
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
    return isArabic ? scaled + 2.0 : scaled + 1.0;
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => baseScaler.textScaleFactor;
}
