import 'mosque.dart';
import 'place.dart';

class Orphanage implements Place {
  @override
  final String id;
  @override
  final String name;
  @override
  final String nameAr;
  final String type;

  final String? zoneId;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String address;
  @override
  final String? image;
  final String? about;
  final String? aboutAr;
  final bool isHighNeed;
  final int? capacity;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Zone? zone;

  Orphanage({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.type,
    this.zoneId,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.image,
    this.about,
    this.aboutAr,
    required this.isHighNeed,
    this.capacity,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.zone,
  });

  factory Orphanage.fromJson(Map<String, dynamic> json) {
    return Orphanage(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      type: json['type'] as String? ?? '',
      zoneId: json['zoneId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      image: json['image'] as String?,
      about: json['about'] as String?,
      aboutAr: json['aboutAr'] as String?,
      isHighNeed: json['isHighNeed'] as bool? ?? false,
      capacity: json['capacity'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      zone: json['zone'] != null
          ? Zone.fromJson(json['zone'] as Map<String, dynamic>)
          : null,
    );
  }
  @override
  String localizedName(bool isAr) {
    return isAr ? nameAr : name;
  }

  String localizedAbout(bool isAr) {
    if (isAr) {
      return aboutAr ?? about ?? '';
    }
    return about ?? aboutAr ?? '';
  }
}
