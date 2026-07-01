class Product {
  final String id;
  final String name;
  final String? nameAr;
  final String? image;

  Product({
    required this.id,
    required this.name,
    this.nameAr,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['nameAr'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'image': image,
    };
  }
}
