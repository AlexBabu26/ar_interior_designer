import 'package:flutter/material.dart';
import '../domain/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.product.price * item.quantity;
    });
    return total;
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(product: product),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
