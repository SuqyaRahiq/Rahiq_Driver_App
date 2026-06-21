class DriverNotification {
  final String id;
  final String? title;
  final String? message;
  final bool isRead;
  final DateTime? createdAt;
  final String? targetId;
  final String? type;

  DriverNotification({
    required this.id,
    this.title,
    this.message,
    required this.isRead,
    this.createdAt,
    this.targetId,
    this.type,
  });

  factory DriverNotification.fromJson(Map<String, dynamic> json) {
    return DriverNotification(
      id: json['id'] ?? '',
      title: json['title'],
      message: json['message'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      targetId: json['targetId'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String(),
      'targetId': targetId,
      'type': type,
    };
  }
}
