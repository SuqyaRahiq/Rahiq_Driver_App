import 'package:rahiq_driver/data/models/driver/product.dart';
import 'package:rahiq_driver/data/models/driver/supplier.dart';
import 'package:rahiq_driver/data/models/driver/vehicle.dart';

class DriverProfile {
  final String id;
  final String phoneNumber;
  final String countryCode;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final bool? isActive;
  final String? type;
  final String? supplierId;
  final String? productId;
  final String? vehicleId;
  final String? email;
  final String? gender;
  final String? bankFullName;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankIbanNumber;
  final Product? product;
  final Vehicle? vehicle;
  final Supplier? supplier;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isAutoDeliveryEnabled;
  final bool canViewContact;
  final bool canUploadFromGallery;
  final bool canViewPastOrders;

  DriverProfile({
    required this.id,
    required this.phoneNumber,
    required this.countryCode,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.isActive,
    this.type,
    this.supplierId,
    this.productId,
    this.vehicleId,
    this.email,
    this.gender,
    this.bankFullName,
    this.bankName,
    this.bankAccountNumber,
    this.bankIbanNumber,
    this.product,
    this.vehicle,
    this.supplier,
    this.createdAt,
    this.updatedAt,
    this.isAutoDeliveryEnabled = false,
    this.canViewContact = false,
    this.canUploadFromGallery = false,
    this.canViewPastOrders = false,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      countryCode: json['countryCode'] ?? '',
      fullName: json['fullName'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'],
      isActive: json['isActive'],
      type: json['type'],
      supplierId: json['supplierId'],
      productId: json['productId'],
      vehicleId: json['vehicleId'],
      email: json['email'],
      gender: json['gender'],
      bankFullName: json['bankFullName'],
      bankName: json['bankName'],
      bankAccountNumber: json['bankAccountNumber'],
      bankIbanNumber: json['bankIbanNumber'],
      product: json['product'] != null
          ? Product.fromJson(Map<String, dynamic>.from(json['product']))
          : null,
      vehicle: json['vehicle'] != null
          ? Vehicle.fromJson(Map<String, dynamic>.from(json['vehicle']))
          : null,
      supplier: json['supplier'] != null
          ? Supplier.fromJson(Map<String, dynamic>.from(json['supplier']))
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      isAutoDeliveryEnabled: json['isAutoDeliveryEnabled'] ?? false,
      canViewContact: json['canViewContact'] ?? false,
      canUploadFromGallery: json['canUploadFromGallery'] ?? false,
      canViewPastOrders: json['canViewPastOrders'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'fullName': fullName,
      'username': username,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'type': type,
      'supplierId': supplierId,
      'productId': productId,
      'vehicleId': vehicleId,
      'email': email,
      'gender': gender,
      'bankFullName': bankFullName,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankIbanNumber': bankIbanNumber,
      'product': product?.toJson(),
      'vehicle': vehicle?.toJson(),
      'supplier': supplier?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isAutoDeliveryEnabled': isAutoDeliveryEnabled,
      'canViewContact': canViewContact,
      'canUploadFromGallery': canUploadFromGallery,
      'canViewPastOrders': canViewPastOrders,
    };
  }
}
