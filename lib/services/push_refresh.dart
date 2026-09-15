import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:rahiq_driver/services/notification_service.dart';

/// Re-fetches a page's list whenever a push from the backend arrives, so a
/// delivery assigned while the driver is looking at the page shows up without
/// them having to pull to refresh.
///
/// A page only refreshes while it is the one on screen: its route has to be
/// the top one, which rules out a page covered by another route (a details
/// page, the proof submission page). Tabs that are not selected are not
/// mounted at all, so they never get here.
mixin PushRefreshMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<RemoteMessage>? _pushSubscription;
  Timer? _pushRefreshTimer;

  /// Assignments often go out as a burst of pushes, one per order; waiting for
  /// the burst to settle turns it into a single request.
  static const Duration _settleDelay = Duration(seconds: 3);

  /// Fetches the page's list again and calls setState only if it changed.
  /// Must not show a loader or surface an error: the driver did not ask for
  /// this refresh.
  Future<void> refreshListOnPush();

  @override
  void initState() {
    super.initState();
    _pushSubscription = NotificationService().appMessages.listen((_) {
      _pushRefreshTimer?.cancel();
      _pushRefreshTimer = Timer(_settleDelay, () {
        if (!mounted || !(ModalRoute.isCurrentOf(context) ?? true)) return;
        refreshListOnPush();
      });
    });
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    _pushRefreshTimer?.cancel();
    super.dispose();
  }

  /// Whether two lists of JSON maps hold the same data. Values JSON cannot
  /// encode are compared by their string form.
  bool sameJson(List<dynamic> a, List<dynamic> b) =>
      jsonEncode(a, toEncodable: (o) => o.toString()) ==
      jsonEncode(b, toEncodable: (o) => o.toString());
}
