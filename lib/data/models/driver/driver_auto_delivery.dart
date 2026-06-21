class DriverAutoDelivery {
  final String id;
  final String? status;
  final String? deliveryDate;
  final String? customerName;
  final String? customerPhone;
  final String? address;
  final double? latitude;
  final double? longitude;

  DriverAutoDelivery({
    required this.id,
    this.status,
    this.deliveryDate,
    this.customerName,
    this.customerPhone,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory DriverAutoDelivery.fromJson(Map<String, dynamic> json) {
    return DriverAutoDelivery(
      id: json['id'] ?? '',
      status: json['status'],
      deliveryDate: json['deliveryDate'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      address: json['address'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'deliveryDate': deliveryDate,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
