import 'driver_order_response.dart';
import 'normal_sub_order.dart';

class PastOrdersResponse {
  final List<NormalSubOrder> items;
  final DriverOrderMeta? meta;

  PastOrdersResponse({
    required this.items,
    this.meta,
  });

  factory PastOrdersResponse.fromJson(Map<String, dynamic> json) {
    return PastOrdersResponse(
      items: (json['items'] as List?)
              ?.map((item) => NormalSubOrder.fromJson(item))
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
