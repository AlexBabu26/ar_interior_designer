class User {
  final String id;
  final String email;
  final String? password;

  User({required this.id, required this.email, this.password});
}

class CartItem {
  final String productId;
  final int quantity;
  final double unitPrice;

  CartItem({required this.productId, required this.quantity, required this.unitPrice});
}

class Cart {
  final String userId;
  final List<CartItem> items;

  Cart({required this.userId, required this.items});

  double get total => items.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));
}
