import 'driver_order.dart';

class DriverOrderMeta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  DriverOrderMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory DriverOrderMeta.fromJson(Map<String, dynamic> json) {
    return DriverOrderMeta(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'page': page,
        'limit': limit,
        'totalPages': totalPages,
      };
}

class DriverOrderResponse {
  final List<DriverOrder> items;
  final DriverOrderMeta? meta;

  DriverOrderResponse({
    required this.items,
    this.meta,
  });

  factory DriverOrderResponse.fromJson(Map<String, dynamic> json) {
    return DriverOrderResponse(
      items: (json['items'] as List?)
              ?.map((item) => DriverOrder.fromJson(item))
              .toList() ??
          [],
      meta: json['meta'] != null ? DriverOrderMeta.fromJson(json['meta']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'meta': meta?.toJson(),
      };
}
