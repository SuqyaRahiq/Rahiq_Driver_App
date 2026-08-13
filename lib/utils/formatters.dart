import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// One place for every user-facing date and time in the app, so both languages
/// stay consistent. Mirrors the customer app's `Formatters`.
class Formatters {
  /// Locales used for formatting. Both keep Western digits: intl follows CLDR,
  /// where `ar` uses Latin digits and only translates the words, which is
  /// exactly what the app wants — Arabic month names and ص/م, never ٠١٢.
  static const String arabicLocale = 'ar';
  static const String englishLocale = 'en_US';

  /// The full date, e.g. `20 June 2026` / `20 يونيو 2026`.
  static const String _datePattern = 'd MMMM yyyy';

  /// The clock time, e.g. `12:30 PM` / `12:30 م`.
  static const String _timePattern = 'h:mm a';

  /// Month and year only, e.g. `June 2026` / `يونيو 2026`.
  static const String _monthYearPattern = 'MMMM yyyy';

  /// True when the app is currently running in Arabic.
  static bool isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  /// The intl locale name for the app's language.
  static String localeOf(BuildContext context) =>
      isArabic(context) ? arabicLocale : englishLocale;

  /// `20 June 2026` in English, `20 يونيو 2026` in Arabic.
  static String formatDate(BuildContext context, DateTime date) =>
      DateFormat(_datePattern, localeOf(context)).format(date.toLocal());

  /// `12:30 PM` in English, `12:30 م` in Arabic.
  static String formatTime(BuildContext context, DateTime date) =>
      DateFormat(_timePattern, localeOf(context)).format(date.toLocal());

  /// `20 June 2026, 12:30 PM` in English, `20 يونيو 2026، 12:30 م` in Arabic
  /// (the comma is the Arabic one, U+060C).
  static String formatDateTime(BuildContext context, DateTime date) {
    final separator = isArabic(context) ? '، ' : ', ';
    return '${formatDate(context, date)}$separator${formatTime(context, date)}';
  }

  /// `June 2026` in English, `يونيو 2026` in Arabic.
  static String formatMonthYear(BuildContext context, DateTime date) =>
      DateFormat(_monthYearPattern, localeOf(context)).format(date.toLocal());

  /// The weekday on its own, e.g. `Mon` / `الاثنين`.
  static String formatWeekday(BuildContext context, DateTime date) =>
      DateFormat.E(localeOf(context)).format(date.toLocal());
}
