import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/order.dart';

abstract class OrderRepository {
  Future<List<Order>> getOrders();

  Future<String> checkoutActiveCart();
  Future<Order?> getOrderById(String id);
}

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<String> checkoutActiveCart() async {
    final response = await _client.rpc('checkout_active_cart');
    return response as String;
  }

  @override
  Future<List<Order>> getOrders() async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*, products(image_url))')
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Order.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<Order?> getOrderById(String id) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*, products(image_url))')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Order.fromJson(Map<String, dynamic>.from(response as Map));
  }
}
