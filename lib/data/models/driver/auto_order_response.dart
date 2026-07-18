import 'auto_order_item.dart';

class AutoOrderMeta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  AutoOrderMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory AutoOrderMeta.fromJson(Map<String, dynamic> json) {
    return AutoOrderMeta(
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

class AutoOrderResponse {
  final List<AutoOrderItem> items;
  final AutoOrderMeta? meta;

  AutoOrderResponse({
    required this.items,
    this.meta,
  });

  factory AutoOrderResponse.fromJson(Map<String, dynamic> json) {
    return AutoOrderResponse(
      items: (json['items'] as List?)
              ?.map((item) => AutoOrderItem.fromJson(item))
              .toList() ??
          [],
      meta: json['meta'] != null ? AutoOrderMeta.fromJson(json['meta']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'meta': meta?.toJson(),
      };
}
