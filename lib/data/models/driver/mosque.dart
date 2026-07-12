import 'city.dart';
import 'place.dart';

class Mosque extends Place {
  @override
  final String id;
  @override
  final String name;
  @override
  final String nameAr;
  final int beneficiaryCount;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String address;
  @override
  final String image;
  final bool isActive;
  final Zone? zone;

  Mosque({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.beneficiaryCount,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.image,
    required this.zone,
    required this.isActive,
  });

  factory Mosque.fromJson(Map<String, dynamic> json) {
    return Mosque(
      beneficiaryCount: json['beneficiaryCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      image: json['image'] as String? ?? '',
      zone: json['zone'] != null
          ? Zone.fromJson(json['zone'] as Map<String, dynamic>)
          : null,
    );
  }
  @override
  String localizedName(bool isAr) {
    return isAr ? nameAr : name;
  }
}

class Zone {
  final String name;
  final String nameAr;
  final City? city;

  Zone({required this.name, required this.nameAr, this.city});

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      city: json['city'] != null
          ? City.fromJson(json['city'] as Map<String, dynamic>)
          : null,
    );
  }

  String localizedName(bool isAr) {
    return isAr ? nameAr : name;
  }
}
