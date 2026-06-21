class AutoOrderItem {
  final int serialNumber;
  final String id;
  final String type;
  final String name;
  final String nameAr;
  final String? image;
  final int totalQuantity;

  AutoOrderItem({
    required this.serialNumber,
    required this.id,
    required this.type,
    required this.name,
    required this.nameAr,
    this.image,
    required this.totalQuantity,
  });

  factory AutoOrderItem.fromJson(Map<String, dynamic> json) {
    return AutoOrderItem(
      serialNumber: (json['serialNumber'] as num?)?.toInt() ?? 0,
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
      image: json['image'],
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'serialNumber': serialNumber,
        'id': id,
        'type': type,
        'name': name,
        'nameAr': nameAr,
        'image': image,
        'totalQuantity': totalQuantity,
      };
}
