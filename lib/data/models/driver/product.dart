class Product {
  final String id;
  final String name;
  final String? nameAr;
  final String? image;
  final num? price;
  final int? serialNumber;

  Product({
    required this.id,
    required this.name,
    this.nameAr,
    this.image,
    this.price,
    this.serialNumber,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['nameAr'],
      image: json['image'],
      price: json['price'],
      serialNumber: json['serialNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'image': image,
      'price': price,
      'serialNumber': serialNumber,
    };
  }
}
