import 'dart:developer';
import 'package:dio/dio.dart';
import '../../models/driver/auto_order_item.dart'; // AutoOrderItem
import '../../models/driver/driver_order.dart';
import '../../models/driver/driver_dashboard_stats.dart';
import '../api_client.dart';
import '../api_exception.dart';

class DriverOrdersApi {
  final ApiClient _apiClient;

  DriverOrdersApi(this._apiClient);

  Future<List<DriverOrder>> getNormalOrders() async {
    try {
      final response = await _apiClient.dio.get('/driver/orders/normal');
      log(
        '\x1B[33m*** NORMAL ORDERS GET API RESPONSE ***\n${response.data}\n\x1B[0m',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data']['items'] ?? [];
        return data.map((json) => DriverOrder.fromJson(json)).toList();
      } else {
        throw ApiException(
          response.data['message'] ?? 'Failed to get normal orders',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        (e.response?.data is Map ? e.response?.data['message'] : null) ??
            e.message ??
            'Failed to get normal orders',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<DriverDashboardStats> getDashboardStats() async {
    try {
      final response = await _apiClient.dio.get('/driver/orders/dashboard');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return DriverDashboardStats.fromJson(response.data['data']['stats']);
      } else {
        throw ApiException(
          response.data['message'] ?? 'Failed to get dashboard stats',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        (e.response?.data is Map ? e.response?.data['message'] : null) ??
            e.message ??
            'Failed to get dashboard stats',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> updateNormalOrderLocation(
    String orderId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _apiClient.dio.patch(
        '/driver/orders/normal/location/$orderId',
        data: {'latitude': latitude, 'longitude': longitude},
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(
          response.data['message'] ?? 'Failed to update order location',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        (e.response?.data is Map ? e.response?.data['message'] : null) ??
            e.message ??
            'Failed to update order location',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<dynamic>> getNormalOrderSubOrders(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
        '/driver/orders/normal/location/$orderId',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        var data = response.data['data'];
        if (data is Map && data.containsKey('items')) {
          data = data['items'];
        }
        if (data is List) {
          return data;
        }
        return [];
      } else {
        throw ApiException(
          response.data['message'] ?? 'Failed to get sub orders',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        (e.response?.data is Map ? e.response?.data['message'] : null) ??
            e.message ??
            'Failed to get sub orders',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<AutoOrderItem>> getAutoOrders() async {
    try {
      final response = await _apiClient.dio.get('/driver/orders/auto');
      log(
        '\x1B[33m*** AUTO ORDERS GET API RESPONSE ***\n${response.data}\n\x1B[0m',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> items = response.data['data']['items'] ?? [];
        return items.map((json) => AutoOrderItem.fromJson(json)).toList();
      } else {
        throw ApiException(
          response.data['message'] ?? 'Failed to get auto orders',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        (e.response?.data is Map ? e.response?.data['message'] : null) ??
            e.message ??
            'Failed to get auto orders',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<dynamic>> getAutoOrderDetails(String orderId, String type) async {
    try {
      final response = await _apiClient.dio.get(
        '/driver/orders/auto/$orderId',
        queryParameters: {'type': type},
      );
      log(
        '\x1B[33m*** AUTO ORDER API FULL RESPONSE ***\n${response.data}\n\x1B[0m',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['items'] ?? [];
      } else {
        throw ApiException(
          response.data['message'] ?? 'Failed to get auto order details',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        (e.response?.data is Map ? e.response?.data['message'] : null) ??
            e.message ??
            'Failed to get auto order details',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> confirmSubOrder({
    required String subOrderId,
    required String mosqueFrontImagePath,
    required String mosqueInsideImagePath,
    required String packagesImagePath,
    required String proofVideoPath,
    bool deliveredToDifferentMosque = false,
    String? differentMosqueReason,
    String? deliveredLocationId,
  }) async {
    try {
      FormData formData = FormData.fromMap({});
      if (!mosqueFrontImagePath.startsWith('http')) {
        formData.files.add(
          MapEntry(
            'mosqueFrontImage',
            await MultipartFile.fromFile(mosqueFrontImagePath),
          ),
        );
      }
      if (!mosqueInsideImagePath.startsWith('http')) {
        formData.files.add(
          MapEntry(
            'mosqueInsideImage',
            await MultipartFile.fromFile(mosqueInsideImagePath),
          ),
        );
      }
      if (!packagesImagePath.startsWith('http')) {
        formData.files.add(
          MapEntry(
            'packagesImage',
            await MultipartFile.fromFile(packagesImagePath),
          ),
        );
      }
      if (!proofVideoPath.startsWith('http')) {
        formData.files.add(
          MapEntry(
            'deliveryVideo',
            await MultipartFile.fromFile(proofVideoPath),
          ),
        );
      }

      formData.fields.add(MapEntry('deliveredToDifferentMosque', deliveredToDifferentMosque.toString()));
      if (deliveredToDifferentMosque) {
        if (differentMosqueReason != null && differentMosqueReason.isNotEmpty) {
          formData.fields.add(MapEntry('differentMosqueReason', differentMosqueReason));
        }
        if (deliveredLocationId != null && deliveredLocationId.isNotEmpty) {
          formData.fields.add(MapEntry('deliveredLocationId', deliveredLocationId));
        }
      }

      final response = await _apiClient.dio.post(
        '/driver/orders/sub-orders/$subOrderId/confirm',
        data: formData,
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(
          response.data['message'] ?? 'Failed to confirm sub order',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        (e.response?.data is Map ? e.response?.data['message'] : null) ??
            e.message ??
            'Failed to confirm sub order',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // Future<void> bulkUploadProof({
  //   required String orderId,
  //   required String mosqueFrontImagePath,
  //   required String mosqueInsideImagePath,
  //   required String packagesImagePath,
  //   required List<String> subOrderIds,
  //   String? proofVideoPath,
  // }) async {
  //   try {
  //     FormData formData = FormData.fromMap({
  //       'orderId': orderId,
  //       'mosqueFrontImage': await MultipartFile.fromFile(mosqueFrontImagePath),
  //       'mosqueInsideImage': await MultipartFile.fromFile(
  //         mosqueInsideImagePath,
  //       ),
  //       'packagesImage': await MultipartFile.fromFile(packagesImagePath),
  //     });

  //     for (var id in subOrderIds) {
  //       formData.fields.add(MapEntry('subOrderIds', id));
  //     }

  //     if (proofVideoPath != null) {
  //       formData.files.add(
  //         MapEntry('proofVideo', await MultipartFile.fromFile(proofVideoPath)),
  //       );
  //     }

  //     final response = await _apiClient.dio.post(
  //       '/driver/orders/bulk-upload-proof',
  //       data: formData,
  //     );

  //     if (response.statusCode != 200 || response.data['success'] != true) {
  //       throw ApiException(
  //         response.data['message'] ?? 'Failed to bulk upload proof',
  //         statusCode: response.statusCode,
  //       );
  //     }
  //   } on DioException catch (e) {
  //     throw ApiException(
  //       (e.response?.data is Map ? e.response?.data['message'] : null) ??
  //           e.message ??
  //           'Failed to bulk upload proof',
  //       statusCode: e.response?.statusCode,
  //     );
  //   }
  // }

  Future<void> bulkUploadMosqueImages({
    required String orderId,
    required List<String> subOrderIds,
    required String mosqueFrontImagePath,
    required String mosqueInsideImagePath,
  }) async {
    try {
      FormData formData = FormData.fromMap({'orderId': orderId});

      for (var id in subOrderIds) {
        formData.fields.add(MapEntry('subOrderIds', id));
      }

      if (!mosqueFrontImagePath.startsWith('http')) {
        formData.files.add(
          MapEntry(
            'mosqueFrontImage',
            await MultipartFile.fromFile(mosqueFrontImagePath),
          ),
        );
      }
      if (!mosqueInsideImagePath.startsWith('http')) {
        formData.files.add(
          MapEntry(
            'mosqueInsideImage',
            await MultipartFile.fromFile(mosqueInsideImagePath),
          ),
        );
      }

      final response = await _apiClient.dio.post(
        '/driver/orders/bulk-upload-proof',
        data: formData,
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ApiException(
          response.data['message'] ?? 'Failed to bulk upload mosque images',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        (e.response?.data is Map ? e.response?.data['message'] : null) ??
            e.message ??
            'Failed to bulk upload mosque images',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<Response> getMosques({
    int page = 1,
    int limit = 100,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'limit': limit};
      if (latitude != null) queryParameters['latitude'] = latitude;
      if (longitude != null) queryParameters['longitude'] = longitude;

      final response = await _apiClient.dio.get(
        '/mosques',
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getOrphanages({int page = 1, int limit = 100}) async {
    try {
      final response = await _apiClient.dio.get(
        '/orphanages',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getMiqatMosques({int page = 1, int limit = 100}) async {
    try {
      final response = await _apiClient.dio.get(
        '/meqat-mosques',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
