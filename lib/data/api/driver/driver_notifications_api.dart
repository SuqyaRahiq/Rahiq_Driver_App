import 'package:dio/dio.dart';
import '../../models/driver/driver_notification.dart';
import '../api_client.dart';
import '../api_exception.dart';

class DriverNotificationsApi {
  final ApiClient _apiClient;

  DriverNotificationsApi(this._apiClient);

  Future<List<DriverNotification>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get('/driver/notifications');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => DriverNotification.fromJson(json)).toList();
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to get notifications', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException((e.response?.data is Map ? e.response?.data['message'] : null) ?? e.message ?? 'Failed to get notifications', statusCode: e.response?.statusCode);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/driver/notifications/unread-count');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['count'] ?? 0;
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to get unread count', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException((e.response?.data is Map ? e.response?.data['message'] : null) ?? e.message ?? 'Failed to get unread count', statusCode: e.response?.statusCode);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.dio.patch('/driver/notifications/$notificationId/read');
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(response.data['message'] ?? 'Failed to mark as read', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException((e.response?.data is Map ? e.response?.data['message'] : null) ?? e.message ?? 'Failed to mark as read', statusCode: e.response?.statusCode);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _apiClient.dio.patch('/driver/notifications/read-all');
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(response.data['message'] ?? 'Failed to mark all as read', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException((e.response?.data is Map ? e.response?.data['message'] : null) ?? e.message ?? 'Failed to mark all as read', statusCode: e.response?.statusCode);
    }
  }

  Future<DriverNotification> getNotificationDetails(String notificationId) async {
    try {
      final response = await _apiClient.dio.get('/driver/notifications/$notificationId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return DriverNotification.fromJson(response.data['data']);
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to get notification details', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException((e.response?.data is Map ? e.response?.data['message'] : null) ?? e.message ?? 'Failed to get notification details', statusCode: e.response?.statusCode);
    }
  }
}
