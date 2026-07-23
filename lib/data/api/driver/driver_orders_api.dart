import 'package:dio/dio.dart';
import '../../models/driver/driver_order_response.dart';
import '../../models/driver/driver_dashboard_stats.dart';
import '../../models/driver/normal_sub_order.dart';
import '../../models/driver/auto_order_response.dart';
import '../../models/driver/past_orders_response.dart';
import '../api_client.dart';

class DriverOrdersApi {
  final ApiClient _apiClient;

  DriverOrdersApi(this._apiClient);

  Future<DriverOrderResponse> getNormalOrders({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/driver/orders/normal',
        queryParameters: {'page': page, 'limit': limit},
      );
      return ApiClient.handleResponse(
        response,
        (data) => DriverOrderResponse.fromJson(data['data']),
        fallbackError: 'Failed to get normal orders',
      );
    } on DioException catch (e) {
      return ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to get normal orders',
      );
    }
  }

  Future<DriverDashboardStats?> getDashboardStats({String? eTag}) async {
    try {
      final response = await _apiClient.dio.get(
        '/driver/orders/dashboard',
        options: Options(
          headers: eTag != null ? {'If-None-Match': eTag} : null,
          validateStatus: (status) =>
              status != null && (status == 200 || status == 304),
        ),
      );

      if (response.statusCode == 304) {
        return null;
      }

      final stats = ApiClient.handleResponse(
        response,
        (data) => DriverDashboardStats.fromJson(data['data']['stats']),
        fallbackError: 'Failed to get dashboard stats',
      );

      stats.eTag = response.headers.value('etag');
      return stats;
    } on DioException catch (e) {
      return ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to get dashboard stats',
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
      ApiClient.handleVoidResponse(
        response,
        fallbackError: 'Failed to update order location',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to update order location',
      );
    }
  }

  Future<List<NormalSubOrder>> getNormalOrderSubOrders(
    String orderId, {
    String? sortBy,
    String? sortOrder,
    bool hasNote = false,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (sortBy != null) queryParameters['sortBy'] = sortBy;
      if (sortOrder != null) queryParameters['sortOrder'] = sortOrder;
      if (hasNote) queryParameters['hasNote'] = 'true';

      final response = await _apiClient.dio.get(
        '/driver/orders/normal/location/$orderId',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );
      return ApiClient.handleResponse(response, (data) {
        var items = data['data'];
        if (items is Map && items.containsKey('items')) {
          items = items['items'];
        }
        if (items is List) {
          return items.map((json) => NormalSubOrder.fromJson(json)).toList();
        }
        return <NormalSubOrder>[];
      }, fallbackError: 'Failed to get sub orders');
    } on DioException catch (e) {
      ApiClient.handleDioError(e, fallbackError: 'Failed to get sub orders');
    }
  }

  Future<AutoOrderResponse> getAutoOrders({
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/driver/orders/auto',
        queryParameters: {'page': page, 'limit': limit},
      );
      return ApiClient.handleResponse(
        response,
        (data) => AutoOrderResponse.fromJson(data['data']),
        fallbackError: 'Failed to get auto orders',
      );
    } on DioException catch (e) {
      return ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to get auto orders',
      );
    }
  }

  Future<List<NormalSubOrder>> getAutoOrderDetails(
    String orderId,
    String type, {
    String? sortBy,
    String? sortOrder,
    bool hasNote = false,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'type': type};
      if (sortBy != null) queryParameters['sortBy'] = sortBy;
      if (sortOrder != null) queryParameters['sortOrder'] = sortOrder;
      if (hasNote) queryParameters['hasNote'] = 'true';

      final response = await _apiClient.dio.get(
        '/driver/orders/auto/$orderId',
        queryParameters: queryParameters,
      );
      return ApiClient.handleResponse(response, (data) {
        final List<dynamic> items = data['data']['items'] ?? [];
        return items.map((json) => NormalSubOrder.fromJson(json)).toList();
      }, fallbackError: 'Failed to get auto order details');
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to get auto order details',
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

      formData.fields.add(
        MapEntry(
          'deliveredToDifferentMosque',
          deliveredToDifferentMosque.toString(),
        ),
      );
      if (deliveredToDifferentMosque) {
        if (differentMosqueReason != null && differentMosqueReason.isNotEmpty) {
          formData.fields.add(
            MapEntry('differentMosqueReason', differentMosqueReason),
          );
        }
        if (deliveredLocationId != null && deliveredLocationId.isNotEmpty) {
          formData.fields.add(
            MapEntry('deliveredLocationId', deliveredLocationId),
          );
        }
      }

      final response = await _apiClient.dio.post(
        '/driver/orders/sub-orders/$subOrderId/confirm',
        data: formData,
      );
      ApiClient.handleVoidResponse(
        response,
        fallbackError: 'Failed to confirm sub order',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(e, fallbackError: 'Failed to confirm sub order');
    }
  }

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
      ApiClient.handleVoidResponse(
        response,
        fallbackError: 'Failed to bulk upload mosque images',
      );
    } on DioException catch (e) {
      ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to bulk upload mosque images',
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

  Future<PastOrdersResponse> getPastOrders({
    required int page,
    required int limit,
    String? status, // 'delivered' or 'confirmed'
    String? search,
    String? from,
    String? to,
    String? orderType, // 'NORMAL' or 'AUTO'
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (from != null && from.isNotEmpty) {
        queryParameters['from'] = from;
      }
      if (to != null && to.isNotEmpty) {
        queryParameters['to'] = to;
      }
      if (orderType != null && orderType.isNotEmpty) {
        queryParameters['orderType'] = orderType;
      }

      final response = await _apiClient.dio.get(
        '/driver/orders/past',
        queryParameters: queryParameters,
      );
      return ApiClient.handleResponse(
        response,
        (data) => PastOrdersResponse.fromJson(data['data']),
        fallbackError: 'Failed to get past orders',
      );
    } on DioException catch (e) {
      return ApiClient.handleDioError(
        e,
        fallbackError: 'Failed to get past orders',
      );
    }
  }
}
