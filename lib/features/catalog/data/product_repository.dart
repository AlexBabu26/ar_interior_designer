import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();

  Future<List<Product>> getAdminProducts();

  Future<Product?> getProductById(String id);

  Future<String> saveProduct(Product product);

  Future<void> savePrimaryModel({
    required String productId,
    required String modelUrl,
    String modelType,
  });
}

class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<Product>> getProducts() async {
    final response = await _client
        .from('products')
        .select('*, product_models(*)')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<List<Product>> getAdminProducts() async {
    final response = await _client
        .from('products')
        .select('*, product_models(*)')
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    final response = await _client
        .from('products')
        .select('*, product_models(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Product.fromJson(Map<String, dynamic>.from(response as Map));
  }

  @override
  Future<String> saveProduct(Product product) async {
    final payload = product.toJson();
    if (product.id.isEmpty) {
      payload.remove('id');
    }

    final response = await _client
        .from('products')
        .upsert(payload)
        .select('id')
        .single();

    return response['id'] as String;
  }

  @override
  Future<void> savePrimaryModel({
    required String productId,
    required String modelUrl,
    String modelType = 'glb',
  }) async {
    await _client.from('product_models').update({'is_primary': false}).eq(
      'product_id',
      productId,
    );

    final existing = await _client
        .from('product_models')
        .select('id')
        .eq('product_id', productId)
        .eq('model_url', modelUrl)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('product_models')
          .update({'is_primary': true, 'model_type': modelType})
          .eq('id', existing['id'] as String);
      return;
    }

    await _client.from('product_models').insert({
      'product_id': productId,
      'model_url': modelUrl,
      'model_type': modelType,
      'is_primary': true,
    });
  }
}
