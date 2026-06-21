import 'package:dio/dio.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';

class ApiClient {
  static const String baseUrl =
      'https://api-staging.suqyarahiq.com/api/v1'; // Adjust to real base URL
  late Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final refreshed = await refreshToken();
            if (refreshed) {
              // Retry request
              try {
                final token = AuthStorage.getAccessToken();
                e.requestOptions.headers['Authorization'] = 'Bearer $token';
                final cloneReq = await dio.fetch(e.requestOptions);
                return handler.resolve(cloneReq);
              } catch (retryError) {
                return handler.next(e);
              }
            } else {
              await AuthStorage.clearTokens();
              // Handle global logout if needed
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<bool> refreshToken() async {
    final refreshToken = AuthStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final dioRefresh = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await dioRefresh.post(
        '/driver/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await AuthStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }
}
