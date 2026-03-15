import 'package:supabase_flutter/supabase_flutter.dart';

import '../../catalog/domain/product.dart';
import '../domain/cart_item.dart';

abstract class CartRepository {
  Future<List<CartItem>> loadItems();

  Future<void> addItem(Product product, {int quantity});

  Future<void> removeSingleItem(String productId);

  Future<void> removeItem(String productId);

  Future<void> clear();
}

class SupabaseCartRepository implements CartRepository {
  SupabaseCartRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<void> addItem(Product product, {int quantity = 1}) async {
    final cartId = await _getOrCreateActiveCartId();

    final existing = await _client
        .from('cart_items')
        .select('id, quantity')
        .eq('cart_id', cartId)
        .eq('product_id', product.id)
        .maybeSingle();

    if (existing == null) {
      await _client.from('cart_items').insert({
        'cart_id': cartId,
        'product_id': product.id,
        'quantity': quantity,
      });
      return;
    }

    final existingItem = Map<String, dynamic>.from(existing as Map);
    await _client
        .from('cart_items')
        .update({'quantity': (existingItem['quantity'] as int) + quantity})
        .eq('id', existingItem['id'] as String);
  }

  @override
  Future<void> clear() async {
    final cartId = await _getOrCreateActiveCartId();
    await _client.from('cart_items').delete().eq('cart_id', cartId);
  }

  @override
  Future<List<CartItem>> loadItems() async {
    final cartId = await _getOrCreateActiveCartId();
    final response = await _client
        .from('cart_items')
        .select('quantity, products(*, product_models(*))')
        .eq('cart_id', cartId)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((row) => CartItem.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<void> removeItem(String productId) async {
    final cartId = await _getOrCreateActiveCartId();
    await _client
        .from('cart_items')
        .delete()
        .eq('cart_id', cartId)
        .eq('product_id', productId);
  }

  @override
  Future<void> removeSingleItem(String productId) async {
    final cartId = await _getOrCreateActiveCartId();
    final existing = await _client
        .from('cart_items')
        .select('id, quantity')
        .eq('cart_id', cartId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing == null) {
      return;
    }

    final existingItem = Map<String, dynamic>.from(existing as Map);
    final currentQuantity = existingItem['quantity'] as int;
    if (currentQuantity <= 1) {
      await _client.from('cart_items').delete().eq(
        'id',
        existingItem['id'] as String,
      );
      return;
    }

    await _client
        .from('cart_items')
        .update({'quantity': currentQuantity - 1})
        .eq('id', existingItem['id'] as String);
  }

  Future<String> _getOrCreateActiveCartId() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to access a persistent cart.');
    }

    final existing = await _client
        .from('carts')
        .select('id')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final created = await _client
        .from('carts')
        .insert({'user_id': user.id, 'status': 'active'})
        .select('id')
        .single();

    return created['id'] as String;
  }
}
