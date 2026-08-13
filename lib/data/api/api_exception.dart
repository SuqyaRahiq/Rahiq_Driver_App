class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  /// True when the request never got an answer (offline, timeout, DNS…),
  /// so callers can show a localized connectivity message instead of
  /// [message], which is only meaningful for server-sent errors.
  final bool isNetworkError;

  ApiException(
    this.message, {
    this.statusCode,
    this.data,
    this.isNetworkError = false,
  });

  @override
  String toString() {
    return message;
  }
}
