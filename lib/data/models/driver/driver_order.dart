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
  
  // New fields
  final String? name;
  final String? nameAr;
  final String? image;
  final Map<String, dynamic>? city;
  final Map<String, dynamic>? zone;
  final int? totalQuantity;
  final int? serialNumber;

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
    this.name,
    this.nameAr,
    this.image,
    this.city,
    this.zone,
    this.totalQuantity,
    this.serialNumber,
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
      name: json['name'],
      nameAr: json['nameAr'],
      image: json['image'],
      city: json['city'],
      zone: json['zone'],
      totalQuantity: json['totalQuantity'],
      serialNumber: json['serialNumber'],
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
      'name': name,
      'nameAr': nameAr,
      'image': image,
      'city': city,
      'zone': zone,
      'totalQuantity': totalQuantity,
      'serialNumber': serialNumber,
    };
  }
}
