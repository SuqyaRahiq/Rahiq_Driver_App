import 'package:flutter/services.dart';

/// Folds Arabic-Indic digits to the Western digits the app displays.
///
/// The app shows every number — dates, times, quantities, phone numbers — in
/// Western digits in both languages. Only the *words* change with the
/// language: `20 June 2026` becomes `20 يونيو 2026`, never `٢٠ يونيو ٢٠٢٦`.
///
/// Almost nothing the app formats itself can break that. Dart's `toString()`,
/// `padLeft` and string interpolation are ASCII, and `intl`'s `ar` locale
/// carries `ZERO_DIGIT: '0'`, so `Formatters`, Flutter's date picker and the
/// rest of `MaterialLocalizations` already produce Western digits. The one
/// thing that is not structurally guaranteed is the numbering system CLDR
/// ships for a locale — which is data, and has changed before — so
/// `Formatters` runs its output through [toLatin] as a backstop.
///
/// Two things outside that do need folding:
///
///  - the OS reverse geocoder. The app chooses the locale it is asked in, so
///    it owns the digits that come back — see `_resolveCustomerAddress`.
///  - the driver's own keyboard. An Arabic layout's number row emits ٠-٩,
///    which [LatinDigitsInputFormatter] catches.
///
/// Text that arrives from the backend is deliberately left alone — it is
/// shown as the server wrote it.
class Digits {
  const Digits._();

  static const int _asciiZero = 0x30; // '0'

  /// `٠`-`٩`, what an Arabic keyboard's number row emits.
  static const int _arabicIndicZero = 0x0660;

  /// `۰`-`۹`, the Persian/Urdu shapes. Rare here, but they cost nothing to
  /// cover and are equally unreadable to someone expecting Western digits.
  static const int _extendedArabicIndicZero = 0x06F0;

  /// `٫` and `٬`. These have no use outside a number, so folding them to `.`
  /// and `,` cannot damage surrounding prose — and leaving them behind would
  /// turn `١٢٫٥` into the half-converted `12٫5`.
  static const int _arabicDecimalSeparator = 0x066B;
  static const int _arabicThousandsSeparator = 0x066C;

  /// Whether [text] carries anything this class would rewrite.
  ///
  /// Every conversion below is one UTF-16 code unit to one UTF-16 code unit,
  /// so a folded string always has the same length as its input — which is
  /// what lets [LatinDigitsInputFormatter] leave the caret where it was.
  static bool hasNonLatinDigits(String text) {
    for (var i = 0; i < text.length; i++) {
      if (_fold(text.codeUnitAt(i)) != null) return true;
    }
    return false;
  }

  /// [text] with every Arabic-Indic digit replaced by its Western equivalent.
  ///
  /// Returns the original instance when there is nothing to fold, which is
  /// every call today — so the backstop in `Formatters` costs one scan of a
  /// short string and no allocation.
  static String toLatin(String text) {
    if (!hasNonLatinDigits(text)) return text;

    final units = List<int>.filled(text.length, 0);
    for (var i = 0; i < text.length; i++) {
      final unit = text.codeUnitAt(i);
      units[i] = _fold(unit) ?? unit;
    }
    return String.fromCharCodes(units);
  }

  /// The Western code unit for [unit], or `null` when it is already fine.
  static int? _fold(int unit) {
    if (unit >= _arabicIndicZero && unit <= _arabicIndicZero + 9) {
      return _asciiZero + unit - _arabicIndicZero;
    }
    if (unit >= _extendedArabicIndicZero &&
        unit <= _extendedArabicIndicZero + 9) {
      return _asciiZero + unit - _extendedArabicIndicZero;
    }
    if (unit == _arabicDecimalSeparator) return 0x2E; // '.'
    if (unit == _arabicThousandsSeparator) return 0x2C; // ','
    return null;
  }
}

/// Rewrites Arabic-Indic digits as they are typed.
///
/// An Arabic soft keyboard emits ٠-٩ from its number row, so without this a
/// login username, a bank account number or an IBAN would be shown — and
/// sent — in digits neither the API nor the bank recognises.
///
/// Only for fields whose value has to be machine-readable. Search boxes
/// deliberately go without it: the driver searches Arabic content — mosque
/// names, addresses — and must be free to type Arabic, digits included.
///
/// The fold is length-preserving (see [Digits.hasNonLatinDigits]), so
/// [TextEditingValue.selection] and `composing` carry over untouched and the
/// caret does not jump to the end mid-word.
class LatinDigitsInputFormatter extends TextInputFormatter {
  const LatinDigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final folded = Digits.toLatin(newValue.text);
    if (identical(folded, newValue.text)) return newValue;
    return newValue.copyWith(text: folded);
  }
}
