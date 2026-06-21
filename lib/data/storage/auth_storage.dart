import 'package:hive_flutter/hive_flutter.dart';

class AuthStorage {
  static const String _boxName = 'authBox';
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  static const String _languageKey = 'language';
  static const String _userDataKey = 'userData';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  static Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
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
  }

  static bool get isLoggedIn => getAccessToken() != null;

  static Future<void> saveLanguage(String languageCode) async {
    await _box.put(_languageKey, languageCode);
  }

  static String getLanguage() {
    return _box.get(_languageKey, defaultValue: 'en');
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _box.put(_userDataKey, userData);
  }

  static Map<dynamic, dynamic>? getUserData() {
    return _box.get(_userDataKey);
  }
}
