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
    };
  }
}
