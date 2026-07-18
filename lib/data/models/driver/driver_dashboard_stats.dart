class DriverDashboardStats {
  final int assignedCount;
  final int assignedPackagesCount;
  final int deliveredCount;
  final int confirmedCount;
  final int todayDeliveriesCount;
  final int todayPackagesCount;
  final int totalPackagesCount;
  final int normalAssignedCount;
  final int normalAssignedPackagesCount;
  final int autoAssignedCount;
  final int autoAssignedPackagesCount;
  String? eTag;

  DriverDashboardStats({
    required this.assignedCount,
    required this.assignedPackagesCount,
    required this.deliveredCount,
    required this.confirmedCount,
    required this.todayDeliveriesCount,
    required this.todayPackagesCount,
    required this.totalPackagesCount,
    required this.normalAssignedCount,
    required this.normalAssignedPackagesCount,
    required this.autoAssignedCount,
    required this.autoAssignedPackagesCount,
  });

  factory DriverDashboardStats.fromJson(Map<String, dynamic> json) {
    return DriverDashboardStats(
      assignedCount: json['assignedCount'] ?? 0,
      assignedPackagesCount: json['assignedPackagesCount'] ?? 0,
      deliveredCount: json['deliveredCount'] ?? 0,
      confirmedCount: json['confirmedCount'] ?? 0,
      todayDeliveriesCount: json['todayDeliveriesCount'] ?? 0,
      todayPackagesCount: json['todayPackagesCount'] ?? 0,
      totalPackagesCount: json['totalPackagesCount'] ?? 0,
      normalAssignedCount: json['normalAssignedCount'] ?? 0,
      normalAssignedPackagesCount: json['normalAssignedPackagesCount'] ?? 0,
      autoAssignedCount: json['autoAssignedCount'] ?? 0,
      autoAssignedPackagesCount: json['autoAssignedPackagesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignedCount': assignedCount,
      'assignedPackagesCount': assignedPackagesCount,
      'deliveredCount': deliveredCount,
      'confirmedCount': confirmedCount,
      'todayDeliveriesCount': todayDeliveriesCount,
      'todayPackagesCount': todayPackagesCount,
      'totalPackagesCount': totalPackagesCount,
      'normalAssignedCount': normalAssignedCount,
      'normalAssignedPackagesCount': normalAssignedPackagesCount,
      'autoAssignedCount': autoAssignedCount,
      'autoAssignedPackagesCount': autoAssignedPackagesCount,
    };
  }
}
