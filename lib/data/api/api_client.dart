import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/main.dart';
import 'package:rahiq_driver/pages/auth/login_page.dart';

class ApiClient {
  static const String baseUrl =
      'https://api-staging.suqyarahiq.com/api/v1'; // Adjust to real base URL
  late Dio dio;

  bool _isRefreshing = false;
  final _pendingRequests = <Completer<bool>>[];

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
        logPrint: (obj) => debugPrint(obj.toString()),
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
          logPrint: (obj) => debugPrint(obj.toString()),
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
}
