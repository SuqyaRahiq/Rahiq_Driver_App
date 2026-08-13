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

  /// Endpoints that must NEVER go through the 401 → refresh → retry flow.
  /// A 401 from these is the server's actual answer (bad credentials, a
  /// blocked driver, a dead refresh token) — not an expired access token.
  /// Refreshing and replaying them loops forever and swallows the real
  /// error message the caller needs to show.
  static const List<String> _authExemptPaths = [
    '/driver/auth/login',
    '/driver/auth/refresh-token',
  ];

  /// Per-request retry budget after a successful refresh, so a request that
  /// keeps coming back 401 can never bounce between refresh and retry.
  static const String _retryKey = '_retry_count';
  static const int _maxRetryCount = 1;

  bool _isAuthExempt(String path) =>
      _authExemptPaths.any((exempt) => path.contains(exempt));

  /// The language the app is currently rendered in — `en` or `ar` — for the
  /// `Accept-Language` header, so the server's own messages come back in the
  /// language the driver is reading.
  ///
  /// [localeNotifier] is the source of truth: the language switch writes it
  /// before persisting, so it is never behind. The fallbacks cover callers
  /// that reach the API before `main()` has set it up, or from an isolate
  /// that never ran `main()` at all — a request must not die on a `late`
  /// field over a header.
  static String get appLanguageCode {
    try {
      return localeNotifier.value.languageCode;
    } catch (_) {
      // Notifier not initialized yet — fall back to what was persisted.
    }
    try {
      return AuthStorage.getLanguage();
    } catch (_) {
      // Hive box not open in this isolate either.
    }
    return 'en';
  }

  int _retryCount(RequestOptions options) =>
      (options.extra[_retryKey] ?? 0) as int;

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
          if (_isAuthExempt(options.path)) {
            // Never queue login behind an in-flight refresh, and never send
            // a stale bearer token with it.
            options.headers['Accept-Language'] = appLanguageCode;
            return handler.next(options);
          }

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
          options.headers['Accept-Language'] = appLanguageCode;
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

          if (e.response?.statusCode == 401 &&
              !_isAuthExempt(e.requestOptions.path)) {
            if (_retryCount(e.requestOptions) >= _maxRetryCount) {
              // Already refreshed once and this request still comes back
              // 401 — the session is genuinely dead (revoked, blocked,
              // deleted), so stop replaying it and send the user to login.
              await AuthStorage.clearTokens();
              _navigateToLogin();
              return handler.next(e);
            }

            if (!_isRefreshing) {
              _isRefreshing = true;
              bool refreshed;
              try {
                refreshed = await refreshToken();
              } catch (_) {
                // Network/server error during refresh — don't destroy the
                // session over a transient failure. Surface the original
                // error and let the user retry the action.
                _isRefreshing = false;
                for (var completer in _pendingRequests) {
                  completer.complete(false);
                }
                _pendingRequests.clear();
                return handler.next(e);
              }
              _isRefreshing = false;

              if (refreshed) {
                for (var completer in _pendingRequests) {
                  completer.complete(true);
                }
                _pendingRequests.clear();

                try {
                  final token = AuthStorage.getAccessToken();
                  e.requestOptions.headers['Authorization'] = 'Bearer $token';
                  e.requestOptions.extra[_retryKey] =
                      _retryCount(e.requestOptions) + 1;
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
                  e.requestOptions.extra[_retryKey] =
                      _retryCount(e.requestOptions) + 1;
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
    // Already there. A background request that 401s while the driver is on
    // the login screen must not push a second one over it — that rebuilds the
    // page from scratch and wipes the username and password mid-typing.
    if (LoginPage.isShowing) return;

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
      // A bare Dio on purpose — it must not run the interceptor below and
      // recurse — so the header the interceptor would have added is set here.
      final dioRefresh = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {'Accept-Language': appLanguageCode},
        ),
      );
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
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      // 4xx = the refresh token itself is invalid/expired → return false
      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        return false;
      }
      // Network / server errors → rethrow so callers can distinguish
      // a connectivity blip from a genuinely dead session.
      rethrow;
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
  ///
  /// The server's own `message` wins — it is already localized via the
  /// `Accept-Language` header. Dio's own `e.message` is never surfaced: on a
  /// bad response it is a multi-line explanation of HTTP status codes, which
  /// is not something to put in a snackbar.
  static Never handleDioError(
    DioException e, {
    String fallbackError = 'Request failed',
  }) {
    final data = e.response?.data;
    final apiMessage = data is Map ? data['message']?.toString() : null;

    const networkTypes = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    };

    throw ApiException(
      apiMessage ?? fallbackError,
      statusCode: e.response?.statusCode,
      isNetworkError: networkTypes.contains(e.type),
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
