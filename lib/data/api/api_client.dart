import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/main.dart';
import 'package:rahiq_driver/pages/auth/login_page.dart';
import 'api_exception.dart';

class ApiClient {
  static const String baseUrl =
      'https://api-staging.suqyarahiq.com/api/v1'; // Adjust to real base URL

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  bool _isRefreshing = false;
  final _pendingRequests = <Completer<bool>>[];

  ApiClient._internal() {
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
        logPrint: (obj) => log(obj.toString()),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_isRefreshing) {
            final completer = Completer<bool>();
            _pendingRequests.add(completer);
            final result = await completer.future;
            if (!result) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Token refresh failed',
                ),
              );
            }
          }
          final token = AuthStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept-Language'] =
              localeNotifier.value.languageCode;
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          DioException customException = e;
          if (e.response?.data is Map && e.response?.data['message'] != null) {
            customException = ApiDioException(
              requestOptions: e.requestOptions,
              apiMessage: e.response!.data['message'].toString(),
              response: e.response,
              type: e.type,
              error: e.error,
              message: e.message,
            );
          }
          e = customException;

          if (e.response?.statusCode == 401) {
            if (!_isRefreshing) {
              _isRefreshing = true;
              final refreshed = await refreshToken();
              _isRefreshing = false;

              if (refreshed) {
                for (var completer in _pendingRequests) {
                  completer.complete(true);
                }
                _pendingRequests.clear();

                try {
                  final token = AuthStorage.getAccessToken();
                  e.requestOptions.headers['Authorization'] = 'Bearer $token';
                  final cloneReq = await dio.fetch(e.requestOptions);
                  return handler.resolve(cloneReq);
                } catch (retryError) {
                  return handler.next(e);
                }
              } else {
                for (var completer in _pendingRequests) {
                  completer.complete(false);
                }
                _pendingRequests.clear();
                await AuthStorage.clearTokens();
                _navigateToLogin();
                return handler.next(e);
              }
            } else {
              final completer = Completer<bool>();
              _pendingRequests.add(completer);
              final result = await completer.future;
              if (result) {
                try {
                  final token = AuthStorage.getAccessToken();
                  e.requestOptions.headers['Authorization'] = 'Bearer $token';
                  final cloneReq = await dio.fetch(e.requestOptions);
                  return handler.resolve(cloneReq);
                } catch (retryError) {
                  return handler.next(e);
                }
              } else {
                return handler.next(e);
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  void _navigateToLogin() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<bool> refreshToken() async {
    final refreshToken = AuthStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final dioRefresh = Dio(BaseOptions(baseUrl: baseUrl));
      dioRefresh.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => log(obj.toString()),
        ),
      );
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

  // ── API Response Helpers ─────────────────────────────────────────────

  /// Validates a successful API response and returns the data.
  /// Throws [ApiException] if the response indicates failure.
  static T handleResponse<T>(
    Response response,
    T Function(dynamic data) mapper, {
    String fallbackError = 'Request failed',
  }) {
    if (response.statusCode == 200 && response.data['success'] == true) {
      return mapper(response.data);
    }
    throw ApiException(
      response.data['message'] ?? fallbackError,
      statusCode: response.statusCode,
    );
  }

  /// Validates a successful API response that returns no meaningful data.
  /// Throws [ApiException] if the response indicates failure.
  static void handleVoidResponse(
    Response response, {
    String fallbackError = 'Request failed',
  }) {
    if (response.statusCode != 200 || response.data['success'] != true) {
      throw ApiException(
        response.data['message'] ?? fallbackError,
        statusCode: response.statusCode,
      );
    }
  }

  /// Converts a [DioException] into a user-friendly [ApiException].
  static Never handleDioError(DioException e, {String fallbackError = 'Request failed'}) {
    throw ApiException(
      (e.response?.data is Map ? e.response?.data['message'] : null) ??
          e.message ??
          fallbackError,
      statusCode: e.response?.statusCode,
    );
  }
}

class ApiDioException extends DioException {
  final String apiMessage;

  ApiDioException({
    required super.requestOptions,
    required this.apiMessage,
    super.response,
    super.type,
    super.error,
    super.message,
  });

  @override
  String toString() {
    return apiMessage;
  }
}
