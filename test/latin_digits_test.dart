import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rahiq_driver/utils/digits.dart';
import 'package:rahiq_driver/utils/formatters.dart';

/// Pumps a minimal app in [languageCode] and hands back a context inside it,
/// so the formatting helpers can be exercised exactly as a screen would.
Future<BuildContext> _contextIn(
  WidgetTester tester,
  String languageCode,
) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(languageCode),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  final date = DateTime(2026, 6, 20, 12, 30);

  group('Formatters render Western digits in every language', () {
    testWidgets('Arabic: Arabic words, Western digits', (tester) async {
      final context = await _contextIn(tester, 'ar');

      final rendered = {
        'formatDate': Formatters.formatDate(context, date),
        'formatTime': Formatters.formatTime(context, date),
        'formatDateTime': Formatters.formatDateTime(context, date),
        'formatMonthYear': Formatters.formatMonthYear(context, date),
        'formatWeekday': Formatters.formatWeekday(context, date),
      };

      rendered.forEach((name, value) {
        expect(
          Digits.hasNonLatinDigits(value),
          isFalse,
          reason: '$name produced Arabic-Indic digits: $value',
        );
      });

      // The words still localize — this must not have been achieved by
      // quietly falling back to English.
      expect(rendered['formatDate'], '20 يونيو 2026');
      expect(rendered['formatTime'], '12:30 م');
      expect(rendered['formatMonthYear'], 'يونيو 2026');
    });

    testWidgets('English is unchanged', (tester) async {
      final context = await _contextIn(tester, 'en');

      expect(Formatters.formatDate(context, date), '20 June 2026');
      expect(Formatters.formatTime(context, date), '12:30 PM');
      expect(Formatters.formatMonthYear(context, date), 'June 2026');
    });
  });

  group('Flutter chrome renders Western digits in Arabic', () {
    testWidgets('MaterialLocalizations — the date picker path', (tester) async {
      final context = await _contextIn(tester, 'ar');
      final l10n = MaterialLocalizations.of(context);

      // showDatePicker builds its header, day cells and year grid from these.
      for (final value in [
        l10n.formatFullDate(date),
        l10n.formatMediumDate(date),
        l10n.formatMonthYear(date),
        l10n.formatYear(date),
        l10n.formatDecimal(1234567),
        l10n.formatHour(const TimeOfDay(hour: 12, minute: 30)),
        l10n.formatMinute(const TimeOfDay(hour: 12, minute: 30)),
      ]) {
        expect(
          Digits.hasNonLatinDigits(value),
          isFalse,
          reason: 'MaterialLocalizations produced Arabic-Indic digits: $value',
        );
      }
    });
  });

  group('LatinDigitsInputFormatter', () {
    const formatter = LatinDigitsInputFormatter();

    TextEditingValue typed(String text) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    test('folds digits typed on an Arabic keyboard, caret intact', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typed('٠٥٠١٢٣'),
      );
      expect(result.text, '050123');
      expect(result.selection.baseOffset, 6);
    });

    test('folds Persian shapes and Arabic numeric separators', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        typed('۱۲٬۵۰۰٫۷۵'),
      );
      expect(result.text, '12,500.75');
    });

    test('passes Arabic prose through untouched', () {
      final value = typed('مسجد الملك');
      expect(
        formatter.formatEditUpdate(const TextEditingValue(), value),
        value,
      );
    });

    test('passes an already-Western value through untouched', () {
      final value = typed('050123');
      expect(
        formatter.formatEditUpdate(const TextEditingValue(), value),
        value,
      );
    });
  });

  group('Digits.toLatin', () {
    test('folds digits without disturbing the surrounding Arabic', () {
      expect(Digits.toLatin('شارع ١٢، وحدة ٣٤٥'), 'شارع 12، وحدة 345');
    });

    test('is length preserving, which is what keeps the caret in place', () {
      const input = 'شارع ١٢ — ٢٬٥٠٠٫٧٥';
      expect(Digits.toLatin(input).length, input.length);
    });

    test('allocates nothing when there is nothing to fold', () {
      const text = 'Delivered at 12:30 PM';
      expect(identical(Digits.toLatin(text), text), isTrue);
    });
  });
}
