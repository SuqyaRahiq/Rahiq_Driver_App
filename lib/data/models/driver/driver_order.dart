class DriverOrder {
  final String id;
  final String? status;
  final String? paymentMethod;
  final double? totalAmount;
  final String? customerName;
  final String? customerPhone;
  final String? deliveryAddress;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? type; // 'NORMAL' or 'AUTO'

  DriverOrder({
    required this.id,
    this.status,
    this.paymentMethod,
    this.totalAmount,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.type,
  });

  factory DriverOrder.fromJson(Map<String, dynamic> json) {
    return DriverOrder(
      id: json['id'] ?? '',
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      deliveryAddress: json['deliveryAddress'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'paymentMethod': paymentMethod,
      'totalAmount': totalAmount,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'type': type,
    };
  }
}
