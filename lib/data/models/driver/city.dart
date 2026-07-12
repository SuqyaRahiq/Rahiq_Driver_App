class City {
  final String id;
  final String name;
  final String nameAr;

  City({required this.id, required this.name, required this.nameAr});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
    );
  }

  String localizedName(bool isAr) {
    return isAr ? nameAr : name;
  }
}
