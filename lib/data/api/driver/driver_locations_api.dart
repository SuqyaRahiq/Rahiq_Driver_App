import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/models/driver/locations_context_response.dart';

class DriverLocationsApi {
  final ApiClient _apiClient;

  DriverLocationsApi(this._apiClient);

  Future<LocationsContextResponse> getSubOrderLocationsContext({
    required String subOrderId,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/driver/orders/sub-orders/$subOrderId/locations-context',
        queryParameters: {'page': page, 'limit': limit},
      );

      return LocationsContextResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
