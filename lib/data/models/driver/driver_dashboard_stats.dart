class DriverDashboardStats {
  final int assignedCount;
  final int assignedPackagesCount;
  final int deliveredCount;
  final int confirmedCount;
  final int todayDeliveriesCount;
  final int todayPackagesCount;
  final int totalPackagesCount;

  DriverDashboardStats({
    required this.assignedCount,
    required this.assignedPackagesCount,
    required this.deliveredCount,
    required this.confirmedCount,
    required this.todayDeliveriesCount,
    required this.todayPackagesCount,
    required this.totalPackagesCount,
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
    };
  }
}
