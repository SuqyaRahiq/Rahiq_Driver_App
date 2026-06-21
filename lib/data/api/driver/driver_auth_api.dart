import 'package:dio/dio.dart';
import '../../models/driver/driver_auth_response.dart';
import '../../models/driver/driver_profile.dart';
import '../api_client.dart';
import '../api_exception.dart';

class DriverAuthApi {
  final ApiClient _apiClient;

  DriverAuthApi(this._apiClient);

  Future<DriverAuthResponse> login(Map<String, dynamic> credentials) async {
    try {
      final response = await _apiClient.dio.post(
        '/driver/auth/login',
        data: credentials,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return DriverAuthResponse.fromJson(response.data['data']);
      } else {
        throw ApiException(response.data['message'] ?? 'Login failed', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Login failed', statusCode: e.response?.statusCode);
    }
  }

  Future<void> logout(String refreshToken, String? fcmToken) async {
    try {
      final response = await _apiClient.dio.post(
        '/driver/auth/logout',
        data: {
          'refreshToken': refreshToken,
          if (fcmToken != null) 'fcmToken': fcmToken,
        },
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(response.data['message'] ?? 'Logout failed', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Logout failed', statusCode: e.response?.statusCode);
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
      if (response.statusCode == 200 && response.data['success'] == true) {
        return DriverProfile.fromJson(response.data['data']);
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to update profile', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Failed to update profile', statusCode: e.response?.statusCode);
    }
  }

  Future<DriverProfile> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/driver/auth/me');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return DriverProfile.fromJson(response.data['data']);
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to get profile', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Failed to get profile', statusCode: e.response?.statusCode);
    }
  }

  Future<void> updateDeviceToken(String fcmToken, String deviceType, String deviceId) async {
    try {
      final response = await _apiClient.dio.patch(
        '/driver/auth/device-token',
        data: {
          'fcmToken': fcmToken,
          'deviceType': deviceType,
          'deviceId': deviceId,
        },
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(response.data['message'] ?? 'Failed to update device token', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Failed to update device token', statusCode: e.response?.statusCode);
    }
  }
}
