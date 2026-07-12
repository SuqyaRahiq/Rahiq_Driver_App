import 'mosque.dart' show Zone;
import 'place.dart';

class MeqatMosque implements Place {
  @override
  final String id;
  @override
  final String name;
  @override
  final String nameAr;
  final String type;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String address;
  @override
  final String? image;
  final Zone? zone;

  MeqatMosque({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.image,
    this.zone,
  });

  factory MeqatMosque.fromJson(Map<String, dynamic> json) {
    return MeqatMosque(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      type: json['type'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      image: json['image'] as String?,
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
