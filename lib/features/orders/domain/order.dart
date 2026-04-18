import 'order_item.dart';

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.total,
    required this.createdAt,
    required this.items,
    this.platform = 'Web Store',
    this.paymentMethod = 'Online Payment',
  });

  final String id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;
  final String platform;
  final String paymentMethod;

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['order_items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      items: rawItems,
      platform: json['platform'] as String? ?? 'Web Store',
      paymentMethod: json['payment_method'] as String? ?? 'Online Payment',
    );
  }
}
