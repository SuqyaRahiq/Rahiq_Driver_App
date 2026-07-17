import 'package:dio/dio.dart';
import '../../models/driver/driver_notification.dart';
import '../api_client.dart';

class DriverNotificationsApi {
  final ApiClient _apiClient;

  DriverNotificationsApi(this._apiClient);

  Future<List<DriverNotification>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get('/driver/notifications');
      return ApiClient.handleResponse(
        response,
        (data) {
          final List<dynamic> items = data['data'] ?? [];
          return items.map((json) => DriverNotification.fromJson(json)).toList();
        },
        fallbackError: 'Failed to get notifications',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to get notifications',
      );
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get(
        '/driver/notifications/unread-count',
      );
      return ApiClient.handleResponse(
        response,
        (data) => data['data']['count'] ?? 0,
        fallbackError: 'Failed to get unread count',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to get unread count',
      );
    }
  }

  Future<String> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.dio.patch(
        '/driver/notifications/$notificationId/read',
      );
      return ApiClient.handleResponse(
        response,
        (data) => data['message'] ?? 'Success',
        fallbackError: 'Failed to mark as read',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(e, fallbackError: 'Failed to mark as read');
    }
  }

  Future<String> markAllAsRead() async {
    try {
      final response = await _apiClient.dio.patch(
        '/driver/notifications/read-all',
      );
      return ApiClient.handleResponse(
        response,
        (data) => data['message'] ?? 'Success',
        fallbackError: 'Failed to mark all as read',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to mark all as read',
      );
    }
  }

  Future<String> clearAllNotifications() async {
    try {
      final response = await _apiClient.dio.delete('/driver/notifications');
      return ApiClient.handleResponse(
        response,
        (data) => data['message'] ?? 'Success',
        fallbackError: 'Failed to clear all notifications',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to clear all notifications',
      );
    }
  }

  Future<DriverNotification> getNotificationDetails(
    String notificationId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/driver/notifications/$notificationId',
      );
      return ApiClient.handleResponse(
        response,
        (data) => DriverNotification.fromJson(data['data']),
        fallbackError: 'Failed to get notification details',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to get notification details',
      );
    }
  }
}
