import 'package:rahiq_driver/data/models/driver/product.dart';

class DriverAutoDelivery {
  final String id;
  final String? batchNumber;
  final String? productId;
  final Product? product;
  final int? quantity;
  final String? status;
  final DateTime? assignedAt;
  final DateTime? deliveredAt;
  final int? orderCount;
  final DeliveryLocation? deliveryLocation;

  DriverAutoDelivery({
    required this.id,
    this.batchNumber,
    this.productId,
    this.product,
    this.quantity,
    this.status,
    this.assignedAt,
    this.deliveredAt,
    this.orderCount,
    this.deliveryLocation,
  });

  factory DriverAutoDelivery.fromJson(Map<String, dynamic> json) {
    return DriverAutoDelivery(
      id: json['id'] ?? '',
      batchNumber: json['batchNumber'],
      productId: json['productId'],
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? ''),
      status: json['status'],
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'])
          : null,
      orderCount: json['orderCount'] is int
          ? json['orderCount']
          : int.tryParse(json['orderCount']?.toString() ?? ''),
      deliveryLocation: json['deliveryLocation'] != null
          ? DeliveryLocation.fromJson(json['deliveryLocation'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchNumber': batchNumber,
      'productId': productId,
      'product': product?.toJson(),
      'quantity': quantity,
      'status': status,
      'assignedAt': assignedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'orderCount': orderCount,
      'deliveryLocation': deliveryLocation?.toJson(),
    };
  }
}

class DeliveryLocation {
  final CampaignInfo? campaign;
  final CityInfo? city;
  final MosqueInfo? mosque;

  DeliveryLocation({
    this.campaign,
    this.city,
    this.mosque,
  });

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    return DeliveryLocation(
      campaign: json['campaign'] != null ? CampaignInfo.fromJson(json['campaign']) : null,
      city: json['city'] != null ? CityInfo.fromJson(json['city']) : null,
      mosque: json['mosque'] != null ? MosqueInfo.fromJson(json['mosque']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campaign': campaign?.toJson(),
      'city': city?.toJson(),
      'mosque': mosque?.toJson(),
    };
  }
}

class CampaignInfo {
  final String? title;
  final String? titleAr;

  CampaignInfo({
    this.title,
    this.titleAr,
  });

  factory CampaignInfo.fromJson(Map<String, dynamic> json) {
    return CampaignInfo(
      title: json['title'],
      titleAr: json['titleAr'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'titleAr': titleAr,
    };
  }
}

class CityInfo {
  final String? id;
  final String? name;
  final String? nameAr;

  CityInfo({
    this.id,
    this.name,
    this.nameAr,
  });

  factory CityInfo.fromJson(Map<String, dynamic> json) {
    return CityInfo(
      id: json['id'],
      name: json['name'],
      nameAr: json['nameAr'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
    };
  }
}

class MosqueInfo {
  final String? id;
  final String? name;
  final String? nameAr;
  final String? address;
  final double? latitude;
  final double? longitude;

  MosqueInfo({
    this.id,
    this.name,
    this.nameAr,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory MosqueInfo.fromJson(Map<String, dynamic> json) {
    return MosqueInfo(
      id: json['id'],
      name: json['name'],
      nameAr: json['nameAr'],
      address: json['address'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
