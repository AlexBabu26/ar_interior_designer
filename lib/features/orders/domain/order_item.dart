class OrderItem {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.imageUrl,
  });

  final String id;
  final String? productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final String? imageUrl;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    String? imgUrl;
    final productsInfo = json['products'];
    if (productsInfo is Map) {
      imgUrl = productsInfo['image_url'] as String?;
    }

    return OrderItem(
      id: json['id'] as String,
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      lineTotal: (json['line_total'] as num).toDouble(),
      imageUrl: imgUrl,
    );
  }
}
