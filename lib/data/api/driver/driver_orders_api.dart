import 'dart:developer';
import 'package:dio/dio.dart';
import '../../models/driver/auto_order_item.dart'; // AutoOrderItem
import '../../models/driver/driver_order.dart';
import '../api_client.dart';
import '../api_exception.dart';

class DriverOrdersApi {
  final ApiClient _apiClient;

  DriverOrdersApi(this._apiClient);

  Future<List<DriverOrder>> getNormalOrders() async {
    try {
      final response = await _apiClient.dio.get('/driver/orders/normal');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data']['items'] ?? [];
        return data.map((json) => DriverOrder.fromJson(json)).toList();
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to get normal orders', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Failed to get normal orders', statusCode: e.response?.statusCode);
    }
  }

  Future<void> updateNormalOrderLocation(String orderId, double latitude, double longitude) async {
    try {
      final response = await _apiClient.dio.patch(
        '/driver/orders/normal/location/$orderId',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(response.data['message'] ?? 'Failed to update order location', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Failed to update order location', statusCode: e.response?.statusCode);
    }
  }

  Future<List<String>> getNormalOrderSubOrders(String orderId) async {
    try {
      final response = await _apiClient.dio.get('/driver/orders/normal/location/$orderId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        var data = response.data['data'];
        if (data is Map && data.containsKey('items')) {
          data = data['items'];
        }
        if (data is List) {
          return data.map<String>((e) => e is Map ? (e['id']?.toString() ?? e.toString()) : e.toString()).toList();
        }
        return [];
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to get sub orders', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Failed to get sub orders', statusCode: e.response?.statusCode);
    }
  }

  Future<List<AutoOrderItem>> getAutoOrders() async {
    try {
      final response = await _apiClient.dio.get('/driver/orders/auto');
      log('\x1B[33m*** AUTO ORDERS GET API RESPONSE ***\n${response.data}\n\x1B[0m');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> items =
            response.data['data']['items'] ?? [];
        return items.map((json) => AutoOrderItem.fromJson(json)).toList();
      } else {
        throw ApiException(
            response.data['message'] ?? 'Failed to get auto orders',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(
          e.response?.data['message'] ?? e.message ?? 'Failed to get auto orders',
          statusCode: e.response?.statusCode);
    }
  }

  Future<List<dynamic>> getAutoOrderDetails(String orderId, String type) async {
    try {
      final response = await _apiClient.dio.get('/driver/orders/auto/$orderId', queryParameters: {'type': type});
      log('\x1B[33m*** AUTO ORDER API FULL RESPONSE ***\n${response.data}\n\x1B[0m');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['items'] ?? [];
      } else {
        throw ApiException(response.data['message'] ?? 'Failed to get auto order details', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Failed to get auto order details', statusCode: e.response?.statusCode);
    }
  }

  Future<void> confirmSubOrder({
    required String subOrderId,
    required String mosqueFrontImagePath,
    required String mosqueInsideImagePath,
    required String packagesImagePath,
    required String proofVideoPath,
  }) async {
    try {
      FormData formData = FormData.fromMap({});
      if (!mosqueFrontImagePath.startsWith('http')) {
        formData.files.add(MapEntry('mosqueFrontImage', await MultipartFile.fromFile(mosqueFrontImagePath)));
      }
      if (!mosqueInsideImagePath.startsWith('http')) {
        formData.files.add(MapEntry('mosqueInsideImage', await MultipartFile.fromFile(mosqueInsideImagePath)));
      }
      if (!packagesImagePath.startsWith('http')) {
        formData.files.add(MapEntry('packagesImage', await MultipartFile.fromFile(packagesImagePath)));
      }
      if (!proofVideoPath.startsWith('http')) {
        formData.files.add(MapEntry('deliveryVideo', await MultipartFile.fromFile(proofVideoPath)));
      }

      final response = await _apiClient.dio.post(
        '/driver/orders/sub-orders/$subOrderId/confirm',
        data: formData,
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(response.data['message'] ?? 'Failed to confirm sub order', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Failed to confirm sub order', statusCode: e.response?.statusCode);
    }
  }

  Future<void> bulkUploadProof({
    required String orderId,
    required String mosqueFrontImagePath,
    required String mosqueInsideImagePath,
    required String packagesImagePath,
    required String subOrderIds,
    String? proofVideoPath,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'orderId': orderId,
        'subOrderIds': subOrderIds,
        'mosqueFrontImage': await MultipartFile.fromFile(mosqueFrontImagePath),
        'mosqueInsideImage': await MultipartFile.fromFile(mosqueInsideImagePath),
        'packagesImage': await MultipartFile.fromFile(packagesImagePath),
      });

      if (proofVideoPath != null) {
        formData.files.add(
          MapEntry('proofVideo', await MultipartFile.fromFile(proofVideoPath)),
        );
      }

      final response = await _apiClient.dio.post(
        '/driver/orders/bulk-upload-proof',
        data: formData,
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(response.data['message'] ?? 'Failed to bulk upload proof', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Failed to bulk upload proof', statusCode: e.response?.statusCode);
    }
  }

  Future<void> bulkUploadMosqueImages({
    required String orderId,
    required String subOrderIds,
    required String mosqueFrontImagePath,
    required String mosqueInsideImagePath,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'orderId': orderId,
        'subOrderIds': subOrderIds,
      });

      if (!mosqueFrontImagePath.startsWith('http')) {
        formData.files.add(MapEntry('mosqueFrontImage', await MultipartFile.fromFile(mosqueFrontImagePath)));
      }
      if (!mosqueInsideImagePath.startsWith('http')) {
        formData.files.add(MapEntry('mosqueInsideImage', await MultipartFile.fromFile(mosqueInsideImagePath)));
      }

      final response = await _apiClient.dio.post(
        '/driver/orders/bulk-upload-proof',
        data: formData,
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(response.data['message'] ?? 'Failed to bulk upload mosque images', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.response?.data['message'] ?? e.message ?? 'Failed to bulk upload mosque images', statusCode: e.response?.statusCode);
    }
  }
}
