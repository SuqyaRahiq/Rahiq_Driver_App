class DriverProfile {
  final String id;
  final String phoneNumber;
  final String countryCode;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final bool? isActive;
  final String? type;
  final String? supplierId;
  final String? productId;
  final String? vehicleId;
  final String? email;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DriverProfile({
    required this.id,
    required this.phoneNumber,
    required this.countryCode,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.isActive,
    this.type,
    this.supplierId,
    this.productId,
    this.vehicleId,
    this.email,
    this.gender,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      countryCode: json['countryCode'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      avatarUrl: json['avatarUrl'],
      isActive: json['isActive'],
      type: json['type'],
      supplierId: json['supplierId'],
      productId: json['productId'],
      vehicleId: json['vehicleId'],
      email: json['email'],
      gender: json['gender'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'type': type,
      'supplierId': supplierId,
      'productId': productId,
      'vehicleId': vehicleId,
      'email': email,
      'gender': gender,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
