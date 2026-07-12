abstract class Place {
  String get id;
  String get name;
  String get nameAr;
  double get latitude;
  double get longitude;
  String get address;
  String? get image;

  String localizedName(bool isAr) {
    return isAr ? nameAr : name;
  }
}
