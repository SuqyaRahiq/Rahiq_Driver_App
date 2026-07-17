import 'package:dio/dio.dart';
import '../../models/driver/driver_auto_delivery.dart';
import '../api_client.dart';

class DriverAutoDeliveriesApi {
  final ApiClient _apiClient;

  DriverAutoDeliveriesApi(this._apiClient);

  Future<List<DriverAutoDelivery>> getAutoDeliveries() async {
    try {
      final response = await _apiClient.dio.get('/driver/auto-deliveries');
      return ApiClient.handleResponse(
        response,
        (data) {
          final List<dynamic> items = data['data'] ?? [];
          return items.map((json) => DriverAutoDelivery.fromJson(json)).toList();
        },
        fallbackError: 'Failed to get auto deliveries',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to get auto deliveries',
      );
    }
  }

  Future<void> confirmAutoDelivery({
    required String deliveryId,
    required String mosqueFrontImage,
    required String mosqueInsideImage,
    required String packagesImage,
    required String deliveryVideo,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (!mosqueFrontImage.startsWith('http'))
          'mosqueFrontImage': await MultipartFile.fromFile(mosqueFrontImage),
        if (!mosqueInsideImage.startsWith('http'))
          'mosqueInsideImage': await MultipartFile.fromFile(mosqueInsideImage),
        if (!packagesImage.startsWith('http'))
          'packagesImage': await MultipartFile.fromFile(packagesImage),
        if (!deliveryVideo.startsWith('http'))
          'deliveryVideo': await MultipartFile.fromFile(deliveryVideo),
      });

      final response = await _apiClient.dio.post(
        '/driver/auto-deliveries/$deliveryId/confirm',
        data: formData,
      );
      ApiClient.handleVoidResponse(
        response,
        fallbackError: 'Failed to confirm auto delivery',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to confirm auto delivery',
      );
    }
  }

  Future<DriverAutoDelivery> getAutoDeliveryDetails(String deliveryId) async {
    try {
      final response = await _apiClient.dio.get(
        '/driver/auto-deliveries/$deliveryId',
      );
      return ApiClient.handleResponse(
        response,
        (data) => DriverAutoDelivery.fromJson(data['data']),
        fallbackError: 'Failed to get auto delivery details',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to get auto delivery details',
      );
    }
  }
}
