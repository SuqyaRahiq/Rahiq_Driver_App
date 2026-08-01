import 'driver_order_response.dart';
import 'normal_sub_order.dart';

class PastOrdersResponse {
  final List<NormalSubOrder> items;
  final DriverOrderMeta? meta;
  final int totalProducts;
  final int totalQuantity;

  PastOrdersResponse({
    required this.items,
    this.meta,
    this.totalProducts = 0,
    this.totalQuantity = 0,
  });

  factory PastOrdersResponse.fromJson(Map<String, dynamic> json) {
    return PastOrdersResponse(
      items: (json['items'] as List?)
              ?.map((item) => NormalSubOrder.fromJson(item))
              .toList() ??
          [],
      meta: json['meta'] != null ? DriverOrderMeta.fromJson(json['meta']) : null,
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'meta': meta?.toJson(),
        'totalProducts': totalProducts,
        'totalQuantity': totalQuantity,
      };
}
