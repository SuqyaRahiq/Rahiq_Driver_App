import 'package:dio/dio.dart';
import '../../models/driver/driver_auth_response.dart';
import '../../models/driver/driver_profile.dart';
import '../api_client.dart';

class DriverAuthApi {
  final ApiClient _apiClient;

  DriverAuthApi(this._apiClient);

  Future<DriverAuthResponse> login(Map<String, dynamic> credentials) async {
    try {
      final response = await _apiClient.dio.post(
        '/driver/auth/login',
        data: credentials,
      );
      return ApiClient.handleResponse(
        response,
        (data) => DriverAuthResponse.fromJson(data['data']),
        fallbackError: 'Login failed',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(e, fallbackError: 'Login failed');
    }
  }

  Future<void> logout(String refreshToken, String? fcmToken) async {
    try {
      final response = await _apiClient.dio.post(
        '/driver/auth/logout',
        data: {'refreshToken': refreshToken, 'fcmToken': ?fcmToken},
      );
      ApiClient.handleVoidResponse(response, fallbackError: 'Logout failed');
    } on DioException catch (e) {
      ApiClient.handleDioError(e, fallbackError: 'Logout failed');
    }
  }

  Future<DriverProfile> updateProfile(String profileImagePath) async {
    try {
      FormData formData = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(profileImagePath),
      });

      final response = await _apiClient.dio.patch(
        '/driver/auth/me',
        data: formData,
      );
      return ApiClient.handleResponse(
        response,
        (data) => DriverProfile.fromJson(data['data']),
        fallbackError: 'Failed to update profile',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(e, fallbackError: 'Failed to update profile');
    }
  }

  Future<DriverProfile> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/driver/auth/me');
      return ApiClient.handleResponse(
        response,
        (data) => DriverProfile.fromJson(data['data']),
        fallbackError: 'Failed to get profile',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(e, fallbackError: 'Failed to get profile');
    }
  }

  Future<void> updateDeviceToken(
    String fcmToken,
    String deviceType,
    String deviceId, {
    String? locale,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/driver/auth/device-token',
        data: {
          'fcmToken': fcmToken,
          'deviceType': deviceType,
          'deviceId': deviceId,
          if (locale != null) 'locale': locale,
        },
      );
      ApiClient.handleVoidResponse(
        response,
        fallbackError: 'Failed to update device token',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to update device token',
      );
    }
  }

  Future<DriverProfile> updateBankAccount(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch(
        '/driver/auth/me/bank-account',
        data: data,
      );
      return ApiClient.handleResponse(
        response,
        (data) => DriverProfile.fromJson(data['data']),
        fallbackError: 'Failed to update bank account',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to update bank account',
      );
    }
  }

  Future<void> updateLocale(String locale, {String? fcmToken}) async {
    try {
      final response = await _apiClient.dio.patch(
        '/driver/auth/locale',
        data: {
          'locale': locale,
          if (fcmToken != null) 'fcmToken': fcmToken,
        },
      );
      ApiClient.handleVoidResponse(
        response,
        fallbackError: 'Failed to update locale',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(e, fallbackError: 'Failed to update locale');
    }
  }

  /// Generate Freshchat JWT Token
  Future<Response> generateFreshchatToken(String freshchatUuid) async {
    try {
      final response = await _apiClient.dio.post(
        '/driver/auth/freshchat-token',
        data: {'freshchatUuid': freshchatUuid},
      );
      return response;
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to generate freshchat token',
      );
    }
  }

  /// Save Freshchat Restore ID
  Future<Response> saveFreshchatRestoreId(String restoreId) async {
    try {
      final response = await _apiClient.dio.post(
        '/driver/auth/freshchat-restore-id',
        data: {'restoreId': restoreId},
      );
      return response;
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to save freshchat restore ID',
      );
    }
  }
}
