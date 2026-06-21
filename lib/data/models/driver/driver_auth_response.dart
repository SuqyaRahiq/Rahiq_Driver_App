import 'driver_profile.dart';

class DriverAuthResponse {
  final String accessToken;
  final String refreshToken;
  final DriverProfile? driver;

  DriverAuthResponse({
    required this.accessToken,
    required this.refreshToken,
    this.driver,
  });

  factory DriverAuthResponse.fromJson(Map<String, dynamic> json) {
    return DriverAuthResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      driver: json['driver'] != null ? DriverProfile.fromJson(json['driver']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      if (driver != null) 'driver': driver!.toJson(),
    };
  }
}
