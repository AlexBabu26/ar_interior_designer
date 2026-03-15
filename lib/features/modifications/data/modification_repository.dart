import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/furniture_modification.dart';
import '../domain/furniture_modification_message.dart';

abstract class ModificationRepository {
  /// List modifications for the current user: as customer (requested_by), carpenter (assigned or open), or admin (all).
  Future<List<FurnitureModification>> listModifications();

  /// Get one modification by id with messages (for chat view).
  Future<FurnitureModification?> getModificationWithMessages(String modificationId);

  /// Create a new modification request for an order item (customer).
  Future<FurnitureModification> createModification({
    required String orderId,
    required String orderItemId,
  });

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
}

class SupabaseModificationRepository implements ModificationRepository {
  SupabaseModificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // Explicit FK hints so Supabase returns order_number and product_name for joined rows.
  static const String _selectBase =
      'id, order_id, order_item_id, requested_by, assigned_carpenter_id, status, created_at, updated_at, orders!furniture_modifications_order_id_fkey(order_number), order_items!furniture_modifications_order_item_id_fkey(product_name)';

  @override
  Future<List<FurnitureModification>> listModifications() async {
    final response = await _client
        .from('furniture_modifications')
        .select(_selectBase)
        .order('updated_at', ascending: false);
    return (response as List<dynamic>)
        .map((row) =>
            FurnitureModification.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<FurnitureModification?> getModificationWithMessages(
      String modificationId) async {
    final response = await _client
        .from('furniture_modifications')
        .select(
            '$_selectBase, furniture_modification_messages(id, modification_id, sender_id, content, created_at)',
        )
        .eq('id', modificationId)
        .maybeSingle();
    if (response == null) return null;
    var mod = FurnitureModification.fromJson(
        Map<String, dynamic>.from(response as Map));
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
    return mod;
  }

  @override
  Future<FurnitureModification> createModification({
    required String orderId,
    required String orderItemId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');

    final response = await _client.from('furniture_modifications').insert({
      'order_id': orderId,
      'order_item_id': orderItemId,
      'requested_by': userId,
    }).select(_selectBase).single();

    return FurnitureModification.fromJson(
        Map<String, dynamic>.from(response as Map));
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
        Map<String, dynamic>.from(response as Map));
  }

  @override
  Future<void> assignCarpenter(String modificationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');

    await _client.from('furniture_modifications').update({
      'assigned_carpenter_id': userId,
      'status': 'in_progress',
    }).eq('id', modificationId);
  }

  @override
  Future<void> updateStatus(String modificationId, String status) async {
    await _client
        .from('furniture_modifications')
        .update({'status': status}).eq('id', modificationId);
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
}
