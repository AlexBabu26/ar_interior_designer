import 'furniture_modification_message.dart';

class FurnitureModification {
  const FurnitureModification({
    required this.id,
    required this.orderId,
    required this.orderItemId,
    required this.requestedBy,
    this.assignedCarpenterId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.orderNumber,
    this.orderItemProductName,
    this.requestedByDisplayName,
    this.messages = const [],
  });

  final String id;
  final String orderId;
  final String orderItemId;
  final String requestedBy;
  final String? assignedCarpenterId;
  final String status; // open, in_progress, completed, cancelled
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? orderNumber;
  final String? orderItemProductName;
  /// Display name or email of the customer who requested (for carpenter/admin header).
  final String? requestedByDisplayName;
  final List<FurnitureModificationMessage> messages;

  factory FurnitureModification.fromJson(Map<String, dynamic> json) {
    final rawMessages =
        (json['furniture_modification_messages'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((m) => FurnitureModificationMessage.fromJson(
                Map<String, dynamic>.from(m)))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final orders = json['orders'] ?? json['order'];
    final orderItems = json['order_items'] ?? json['order_item'];
    final orderMap = orders is Map ? orders : (orders is List && orders.isNotEmpty ? orders.first : null);
    final orderItemMap = orderItems is Map ? orderItems : (orderItems is List && orderItems.isNotEmpty ? orderItems.first : null);
    return FurnitureModification(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      orderItemId: json['order_item_id'] as String,
      requestedBy: json['requested_by'] as String,
      assignedCarpenterId: json['assigned_carpenter_id'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      orderNumber: orderMap is Map ? orderMap['order_number'] as String? : null,
      orderItemProductName:
          orderItemMap is Map ? orderItemMap['product_name'] as String? : null,
      requestedByDisplayName: null,
      messages: rawMessages,
    );
  }

  FurnitureModification copyWith({
    String? id,
    String? orderId,
    String? orderItemId,
    String? requestedBy,
    String? assignedCarpenterId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? orderNumber,
    String? orderItemProductName,
    String? requestedByDisplayName,
    List<FurnitureModificationMessage>? messages,
  }) {
    return FurnitureModification(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderItemId: orderItemId ?? this.orderItemId,
      requestedBy: requestedBy ?? this.requestedBy,
      assignedCarpenterId: assignedCarpenterId ?? this.assignedCarpenterId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      orderNumber: orderNumber ?? this.orderNumber,
      orderItemProductName:
          orderItemProductName ?? this.orderItemProductName,
      requestedByDisplayName:
          requestedByDisplayName ?? this.requestedByDisplayName,
      messages: messages ?? this.messages,
    );
  }
}
