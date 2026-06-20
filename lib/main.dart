import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/splash_page.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rahiq_driver/services/notification_service.dart';
// import 'firebase_options.dart'; // Uncomment after running flutterfire configure

import 'package:intl/date_symbol_data_local.dart';

late ValueNotifier<Locale> localeNotifier;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        return MaterialApp(
          title: 'Rahiq Driver',
          locale: locale,
          debugShowCheckedModeBanner: false,
          scrollBehavior: const MyScrollBehavior(),
          theme: ThemeData(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          home: const SplashPage(),
        );
      },
    );
  }
}
