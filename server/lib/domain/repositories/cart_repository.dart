import '../entities/models.dart';

abstract class CartRepository {
  Future<Cart?> getCart(String userId);
  Future<Cart> createCart(String userId);
  Future<void> saveCart(Cart cart);
}
