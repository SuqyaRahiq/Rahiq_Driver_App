class LocationsContextResponse {
  final bool success;
  final String message;
  final LocationsContextData data;

  LocationsContextResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory LocationsContextResponse.fromJson(Map<String, dynamic> json) {
    return LocationsContextResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: LocationsContextData.fromJson(json['data'] ?? {}),
    );
  }
}

class LocationsContextData {
  final List<Location> items;
  final Meta meta;

  LocationsContextData({required this.items, required this.meta});

  factory LocationsContextData.fromJson(Map<String, dynamic> json) {
    return LocationsContextData(
      items:
          (json['items'] as List?)
              ?.map((item) => Location.fromJson(item))
              .toList() ??
          [],
      meta: Meta.fromJson(json['meta'] ?? {}),
    );
  }
}

class Location {
  final String id;
  final String name;
  final String nameAr;
  final String type;
  final String zoneId;
  final double latitude;
  final double longitude;
  final String address;
  final String? image;
  final String? about;
  final String? aboutAr;
  final bool isHighNeed;
  final int? capacity;
  final int sortOrder;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final Zone zone;

  Location({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.type,
    required this.zoneId,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.image,
    this.about,
    this.aboutAr,
    required this.isHighNeed,
    this.capacity,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.zone,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
      type: json['type'] ?? '',
      zoneId: json['zoneId'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      image: json['image'],
      about: json['about'],
      aboutAr: json['aboutAr'],
      isHighNeed: json['isHighNeed'] ?? false,
      capacity: json['capacity'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      zone: Zone.fromJson(json['zone'] ?? {}),
    );
  }

  String getLocalizedName(bool isArabic) {
    return isArabic ? nameAr : name;
  }
}

class Zone {
  final String name;
  final String nameAr;
  final City city;

  Zone({required this.name, required this.nameAr, required this.city});

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
      city: City.fromJson(json['city'] ?? {}),
    );
  }
}

class City {
  final String id;
  final String name;
  final String nameAr;

  City({required this.id, required this.name, required this.nameAr});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
    );
  }
}

class Meta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Meta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}
