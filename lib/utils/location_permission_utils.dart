import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';

/// If location permission was granted at only "approximate" accuracy
/// (Android's Fine/Coarse toggle, or iOS's Precise Location switch), nudges
/// the OS to show its upgrade-to-precise prompt instead of leaving the app
/// stuck at reduced accuracy until the user manually flips it in Settings.
Future<void> maybeRequestPreciseLocation() async {
  final accuracy = await Geolocator.getLocationAccuracy();
  if (accuracy != LocationAccuracyStatus.reduced) return;

  if (Platform.isIOS) {
    await Geolocator.requestTemporaryFullAccuracy(
      purposeKey: 'PreciseLocationUsage',
    );
  } else {
    // Fine location is already declared in the manifest but wasn't granted,
    // so re-requesting makes Android show its lightweight "switch to precise
    // location?" prompt instead of the full permission dialog again.
    await Geolocator.requestPermission();
  }
}
