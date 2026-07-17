class DriverNotification {
  final String id;
  final String? title;
  final String? body;
  final String? titleAr;
  final String? bodyAr;
  final String? category;
  final String? userId;
  final String? driverId;
  final String? adminId;
  final Map<String, dynamic>? data;
  bool isRead;
  final DateTime? createdAt;

  DriverNotification({
    required this.id,
    this.title,
    this.body,
    this.titleAr,
    this.bodyAr,
    this.category,
    this.userId,
    this.driverId,
    this.adminId,
    this.data,
    required this.isRead,
    this.createdAt,
  });

  factory DriverNotification.fromJson(Map<String, dynamic> json) {
    return DriverNotification(
      id: json['id'] ?? '',
      title: json['title'],
      body: json['body'],
      titleAr: json['titleAr'],
      bodyAr: json['bodyAr'],
      category: json['category'],
      userId: json['userId'],
      driverId: json['driverId'],
      adminId: json['adminId'],
      data: json['data'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'titleAr': titleAr,
      'bodyAr': bodyAr,
      'category': category,
      'userId': userId,
      'driverId': driverId,
      'adminId': adminId,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
