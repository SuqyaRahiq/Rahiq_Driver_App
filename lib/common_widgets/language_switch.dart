import 'package:flutter/material.dart';
import '../main.dart';
import '../data/storage/auth_storage.dart';

class LanguageSwitchButton extends StatelessWidget {
  final bool isFromLogin;
  const LanguageSwitchButton({super.key, required this.isFromLogin});

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    return GestureDetector(
      onTap: () async {
        final newLocaleCode = isArabic ? 'en' : 'ar';
        localeNotifier.value = Locale(newLocaleCode);
        await AuthStorage.saveLanguage(newLocaleCode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          isFromLogin
              ? (isArabic ? 'English' : 'عربي')
              : (isArabic ? 'عربي' : 'English'),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
