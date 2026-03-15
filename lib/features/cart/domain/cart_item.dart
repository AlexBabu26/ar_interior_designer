import '../../catalog/domain/product.dart';

class CartItem {
  CartItem({required this.product, this.quantity = 1});

  final Product product;
  final int quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productPayload = Map<String, dynamic>.from(
      (json['products'] ?? json['product']) as Map,
    );

    return CartItem(
      product: Product.fromJson(productPayload),
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}
