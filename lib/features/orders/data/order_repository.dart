import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/order.dart';

abstract class OrderRepository {
  Future<List<Order>> getOrders();

  Future<void> checkoutActiveCart();
}

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<void> checkoutActiveCart() async {
    await _client.rpc('checkout_active_cart');
  }

  @override
  Future<List<Order>> getOrders() async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Order.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}
