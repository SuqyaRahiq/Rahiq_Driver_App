import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rahiq_driver/data/models/driver/driver_profile.dart';
import 'package:rahiq_driver/services/freshchat_service.dart';

class AuthStorage {
  static const String _boxName = 'authBox';
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  static const String _languageKey = 'language';
  static const String _userDataKey = 'userData';

  static const String _freshchatTokenKey = 'freshchatToken';
  static const String _chatNeedsWelcomeKey = 'chatNeedsWelcome';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(_accessTokenKey, accessToken);
    await _box.put(_refreshTokenKey, refreshToken);
  }

  static String? getAccessToken() {
    return _box.get(_accessTokenKey);
  }

  static String? getRefreshToken() {
    return _box.get(_refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await _box.delete(_accessTokenKey);
    await _box.delete(_refreshTokenKey);
    await _box.delete(_userDataKey);

    try {
      Freshchat.resetUser();
    } catch (e) {
      debugPrint('Failed to reset Freshchat user: $e');
    }
  }

  static Future<void> saveFreshchatToken(String token) async {
    await _box.put(_freshchatTokenKey, token);
  }

  static String? get freshchatToken => _box.get(_freshchatTokenKey);

  static Future<void> setChatNeedsWelcome(bool value) async {
    await _box.put(_chatNeedsWelcomeKey, value);
  }

  /// Defaults to true so a driver who has never opened the chat still gets the
  /// bot's welcome flow on their first visit — there is no conversation yet
  /// for Freshchat to report as resolved.
  static bool get chatNeedsWelcome =>
      _box.get(_chatNeedsWelcomeKey, defaultValue: true) as bool;

  static bool get isLoggedIn => getAccessToken() != null;

  static Future<void> saveLanguage(String languageCode) async {
    await _box.put(_languageKey, languageCode);
  }

  static String getLanguage() {
    return _box.get(_languageKey, defaultValue: 'en');
  }

  static Future<void> saveUserData(DriverProfile userData) async {
    await _box.put(_userDataKey, userData.toJson());

    // Deliberately not awaited. Callers await this method to know the profile
    // is *persisted*; handing it to Freshchat is a side errand that must never
    // hold up what comes next — login used to sit on a spinner here, waiting
    // on a chat SDK that had no answer to give. identifyUser swallows and
    // logs its own failures.
    unawaited(FreshchatService.identifyUser(userData));
  }

  static DriverProfile? getUserData() {
    final data = _box.get(_userDataKey);
    if (data != null) {
      try {
        return DriverProfile.fromJson(Map<String, dynamic>.from(data));
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
