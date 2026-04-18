import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/furniture_modification.dart';
import '../domain/furniture_modification_message.dart';

abstract class ModificationRepository {
  /// List modifications for the current user: as customer (requested_by), carpenter (assigned or open), or admin (all).
  Future<List<FurnitureModification>> listModifications();

  /// Get one modification by id with messages (for chat view).
  Future<FurnitureModification?> getModificationWithMessages(
    String modificationId,
  );

  /// Create a new modification request for an order item (customer).
  Future<FurnitureModification> createModification({
    required String orderId,
    required String orderItemId,
    String? productId,
    String? status,
  });

  /// Promote pending modification chats to 'open' status after an order is placed.
  Future<void> promoteModifications(String orderId);

  /// Add a message to a modification thread.
  Future<FurnitureModificationMessage> addMessage({
    required String modificationId,
    required String content,
  });

  /// Assign the current user (carpenter) to the modification and set status to in_progress.
  Future<void> assignCarpenter(String modificationId);

  /// Update modification status (carpenter or admin).
  Future<void> updateStatus(String modificationId, String status);

  /// Check if a modification already exists for this order item (to show "Open chat" vs "Request modification").
  Future<String?> getModificationIdByOrderItemId(String orderItemId);

  /// Fetch the display name of the assigned carpenter by their user ID.
  Future<String?> getCarpenterDisplayName(String carpenterId);
}

class SupabaseModificationRepository implements ModificationRepository {
  SupabaseModificationRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // Explicit FK hints so Supabase returns order_number and product_name for joined rows.
  static const String _selectBase =
      'id, order_id, order_item_id, requested_by, assigned_carpenter_id, status, created_at, updated_at, product_id, orders!furniture_modifications_order_id_fkey(order_number), order_items!furniture_modifications_order_item_id_fkey(product_name, product_id)';

  @override
  Future<List<FurnitureModification>> listModifications() async {
    final response = await _client
        .from('furniture_modifications')
        .select(_selectBase)
        .order('updated_at', ascending: false);

    final List<FurnitureModification> list = (response as List<dynamic>)
        .map(
          (row) => FurnitureModification.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();

    if (list.isEmpty) return list;

    // Fetch display names manually as we don't have a direct FK for PostgREST to auto-join auth.users vs profiles
    final userIds = list.map((e) => e.requestedBy).toSet().toList();
    final profileRes = await _client
        .from('profiles')
        .select('id, display_name, email')
        .filter('id', 'in', userIds);

    final profileMap = <String, String>{};
    for (final row in (profileRes as List<dynamic>)) {
      final map = row as Map;
      final id = map['id'] as String;
      final name = map['display_name'] as String?;
      final email = map['email'] as String?;
      final displayName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : (email ?? 'Customer');
      profileMap[id] = displayName;
    }

    // Fetch product images
    final productIds = list
        .map((e) => e.productId)
        .whereType<String>()
        .toSet()
        .toList();
    final imageMap = <String, String>{};
    final productNameMap = <String, String>{};
    if (productIds.isNotEmpty) {
      final productRes = await _client
          .from('products')
          .select('id, image_url, name')
          .filter('id', 'in', productIds);
      for (final row in (productRes as List<dynamic>)) {
        final map = row as Map;
        final id = map['id'] as String;
        final imageUrl = map['image_url'] as String?;
        final productName = map['name'] as String?;
        if (imageUrl != null) imageMap[id] = imageUrl;
        if (productName != null) productNameMap[id] = productName;
      }
    }

    return list.map((mod) {
      String name = 'Customer';
      if (profileMap.containsKey(mod.requestedBy)) {
        name = profileMap[mod.requestedBy]!;
      }
      String? imageUrl;
      if (mod.productId != null && imageMap.containsKey(mod.productId)) {
        imageUrl = imageMap[mod.productId];
      }
      return mod.copyWith(
        requestedByDisplayName: name,
        orderItemImageUrl: imageUrl,
        orderItemProductName:
            (mod.productId != null && productNameMap.containsKey(mod.productId))
                ? productNameMap[mod.productId]
                : mod.orderItemProductName,
      );
    }).toList();
  }

  @override
  Future<FurnitureModification?> getModificationWithMessages(
    String modificationId,
  ) async {
    final response = await _client
        .from('furniture_modifications')
        .select(
          '$_selectBase, furniture_modification_messages(id, modification_id, sender_id, content, created_at)',
        )
        .eq('id', modificationId)
        .maybeSingle();
    if (response == null) return null;
    var mod = FurnitureModification.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
    final requestedBy = mod.requestedBy;
    final profileRes = await _client
        .from('profiles')
        .select('display_name, email')
        .eq('id', requestedBy)
        .maybeSingle();
    if (profileRes != null) {
      final map = profileRes as Map<String, dynamic>;
      final name = map['display_name'] as String?;
      final email = map['email'] as String?;
      final displayName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : (email ?? 'Customer');
      mod = mod.copyWith(requestedByDisplayName: displayName);
    }

    // Fetch the real product name from the products table
    if (mod.productId != null) {
      final productRes = await _client
          .from('products')
          .select('name')
          .eq('id', mod.productId!)
          .maybeSingle();
      if (productRes != null) {
        final productName = (productRes as Map)['name'] as String?;
        if (productName != null) {
          mod = mod.copyWith(orderItemProductName: productName);
        }
      }
    }

    return mod;
  }

  @override
  Future<FurnitureModification> createModification({
    required String orderId,
    required String orderItemId,
    String? productId,
    String? status,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');

    final response = await _client
        .from('furniture_modifications')
        .insert({
          'order_id': orderId,
          'order_item_id': orderItemId,
          if (productId != null) 'product_id': productId,
          if (status != null) 'status': status,
          'requested_by': userId,
        })
        .select(_selectBase)
        .single();

    return FurnitureModification.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  @override
  Future<FurnitureModificationMessage> addMessage({
    required String modificationId,
    required String content,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');

    final response = await _client
        .from('furniture_modification_messages')
        .insert({
          'modification_id': modificationId,
          'sender_id': userId,
          'content': content.trim(),
        })
        .select()
        .single();

    return FurnitureModificationMessage.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  @override
  Future<void> assignCarpenter(String modificationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');

    await _client
        .from('furniture_modifications')
        .update({'assigned_carpenter_id': userId, 'status': 'in_progress'})
        .eq('id', modificationId);
  }

  @override
  Future<void> updateStatus(String modificationId, String status) async {
    await _client
        .from('furniture_modifications')
        .update({'status': status})
        .eq('id', modificationId);
  }

  @override
  Future<String?> getModificationIdByOrderItemId(String orderItemId) async {
    final response = await _client
        .from('furniture_modifications')
        .select('id')
        .eq('order_item_id', orderItemId)
        .maybeSingle();
    if (response == null) return null;
    return (response as Map)['id'] as String?;
  }

  @override
  Future<String?> getCarpenterDisplayName(String carpenterId) async {
    final response = await _client
        .from('profiles')
        .select('display_name, email')
        .eq('id', carpenterId)
        .maybeSingle();
    if (response == null) return null;
    final map = response as Map<String, dynamic>;
    final name = map['display_name'] as String?;
    final email = map['email'] as String?;
    return (name != null && name.trim().isNotEmpty) ? name.trim() : email;
  }

  @override
  Future<void> promoteModifications(String orderId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Get the items in this order
    final orderResponse = await _client
        .from('order_items')
        .select('id, product_id')
        .eq('order_id', orderId);

    final items = List<Map<String, dynamic>>.from(orderResponse as List);

    // 2. For each item, find any 'pending_order' modification for this product_id
    // and link it to the order_id and order_item_id, then set status to 'open'
    for (final item in items) {
      final productId = item['product_id'] as String?;
      final orderItemId = item['id'] as String;

      if (productId != null) {
        await _client
            .from('furniture_modifications')
            .update({
              'order_id': orderId,
              'order_item_id': orderItemId,
              'status': 'open',
            })
            .eq('requested_by', userId)
            .eq('product_id', productId)
            .eq('status', 'pending_order');
      }
    }
  }
}
