import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/formatters.dart';

/// Digits the app must never render: Arabic-Indic (٠-٩) and their extended
/// Persian variants (۰-۹).
final _nonWesternDigits = RegExp(r'[\u0660-\u0669\u06F0-\u06F9]');

/// Pumps [builder] under the same localization stack as the app and returns
/// what it produced for [locale].
Future<String> _format(
  WidgetTester tester,
  Locale locale,
  String Function(BuildContext context) builder,
) async {
  late String result;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: Builder(
        builder: (context) {
          result = builder(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}

void main() {
  // 20 June 2026 was a Saturday; 12:30 in the afternoon.
  final date = DateTime(2026, 6, 20, 12, 30);
  const english = Locale('en');
  const arabic = Locale('ar');

  testWidgets('formats the date, time and month in English words', (
    tester,
  ) async {
    expect(
      await _format(tester, english, (c) => Formatters.formatDate(c, date)),
      '20 June 2026',
    );
    expect(
      await _format(tester, english, (c) => Formatters.formatTime(c, date)),
      '12:30 PM',
    );
    expect(
      await _format(tester, english, (c) => Formatters.formatMonthYear(c, date)),
      'June 2026',
    );
    expect(
      await _format(tester, english, (c) => Formatters.formatDateTime(c, date)),
      '20 June 2026, 12:30 PM',
    );
    expect(
      await _format(tester, english, (c) => Formatters.formatWeekday(c, date)),
      'Sat',
    );
  });

  testWidgets('translates the words but keeps Western digits in Arabic', (
    tester,
  ) async {
    expect(
      await _format(tester, arabic, (c) => Formatters.formatDate(c, date)),
      '20 يونيو 2026',
    );
    expect(
      await _format(tester, arabic, (c) => Formatters.formatTime(c, date)),
      '12:30 م',
    );
    expect(
      await _format(tester, arabic, (c) => Formatters.formatMonthYear(c, date)),
      'يونيو 2026',
    );
    expect(
      await _format(tester, arabic, (c) => Formatters.formatDateTime(c, date)),
      '20 يونيو 2026، 12:30 م',
    );
    expect(
      await _format(tester, arabic, (c) => Formatters.formatWeekday(c, date)),
      'السبت',
    );
  });

  testWidgets('renders no Arabic-Indic digits for any month or hour', (
    tester,
  ) async {
    for (var month = 1; month <= 12; month++) {
      for (final hour in <int>[0, 9, 13, 23]) {
        final sample = DateTime(2026, month, 15, hour, 45);
        final rendered = await _format(
          tester,
          arabic,
          (c) =>
              '${Formatters.formatDateTime(c, sample)} '
              '${Formatters.formatMonthYear(c, sample)} '
              '${Formatters.formatWeekday(c, sample)}',
        );
        expect(
          _nonWesternDigits.hasMatch(rendered),
          isFalse,
          reason: 'month $month hour $hour rendered as "$rendered"',
        );
      }
    }
  });
}
