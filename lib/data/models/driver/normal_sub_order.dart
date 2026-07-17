import 'package:rahiq_driver/data/models/driver/product.dart';

class CustomerDetails {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? countryCode;
  final String? address;

  CustomerDetails({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.countryCode,
    this.address,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      countryCode: json['countryCode'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'address': address,
    };
  }
}

class NormalSubOrder {
  final String id;
  final String? subOrderNumber;
  final Product? product;
  final int? quantity;
  final String? deliveryNotes;
  final CustomerDetails? customerDetails;
  final String? assignedDate;
  final List<dynamic>? csNotes;
  final String? status;
  final String? mosqueFrontImage;
  final String? mosqueInsideImage;
  final String? packagesImage;
  final String? deliveryVideo;
  final bool? deliveredToDifferentMosque;
  final String? differentMosqueReason;

  NormalSubOrder({
    required this.id,
    this.subOrderNumber,
    this.product,
    this.quantity,
    this.deliveryNotes,
    this.customerDetails,
    this.assignedDate,
    this.csNotes,
    this.status,
    this.mosqueFrontImage,
    this.mosqueInsideImage,
    this.packagesImage,
    this.deliveryVideo,
    this.deliveredToDifferentMosque,
    this.differentMosqueReason,
  });

  factory NormalSubOrder.fromJson(Map<String, dynamic> json) {
    return NormalSubOrder(
      id: json['id'] ?? '',
      subOrderNumber: json['subOrderNumber'],
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      quantity: json['quantity'],
      deliveryNotes: json['deliveryNotes'],
      customerDetails: json['customerDetails'] != null
          ? CustomerDetails.fromJson(json['customerDetails'])
          : null,
      assignedDate: json['assignedDate'],
      csNotes: json['csNotes'] != null ? List<dynamic>.from(json['csNotes']) : null,
      status: json['status'],
      mosqueFrontImage: json['mosqueFrontImage'],
      mosqueInsideImage: json['mosqueInsideImage'],
      packagesImage: json['packagesImage'],
      deliveryVideo: json['deliveryVideo'],
      deliveredToDifferentMosque: json['deliveredToDifferentMosque'],
      differentMosqueReason: json['differentMosqueReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subOrderNumber': subOrderNumber,
      'product': product?.toJson(),
      'quantity': quantity,
      'deliveryNotes': deliveryNotes,
      'customerDetails': customerDetails?.toJson(),
      'assignedDate': assignedDate,
      'csNotes': csNotes,
      'status': status,
      'mosqueFrontImage': mosqueFrontImage,
      'mosqueInsideImage': mosqueInsideImage,
      'packagesImage': packagesImage,
      'deliveryVideo': deliveryVideo,
      'deliveredToDifferentMosque': deliveredToDifferentMosque,
      'differentMosqueReason': differentMosqueReason,
    };
  }
}
