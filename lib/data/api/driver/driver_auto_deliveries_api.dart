import 'package:dio/dio.dart';
import '../../models/driver/driver_auto_delivery.dart';
import '../api_client.dart';
import '../api_exception.dart';

class DriverAutoDeliveriesApi {
  final ApiClient _apiClient;

  DriverAutoDeliveriesApi(this._apiClient);

  Future<List<DriverAutoDelivery>> getAutoDeliveries() async {
    try {
      final response = await _apiClient.dio.get('/driver/auto-deliveries');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => DriverAutoDelivery.fromJson(json)).toList();
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to get auto deliveries', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Failed to get auto deliveries', statusCode: e.response?.statusCode);
    }
  }

  Future<void> confirmAutoDelivery(String deliveryId) async {
    try {
      final response = await _apiClient.dio.patch('/driver/auto-deliveries/$deliveryId/confirm');
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(response.data['message'] ?? 'Failed to confirm auto delivery', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Failed to confirm auto delivery', statusCode: e.response?.statusCode);
    }
  }
}
