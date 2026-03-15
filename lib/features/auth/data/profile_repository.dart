import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_profile.dart';

abstract class ProfileRepository {
  Future<AppProfile?> fetchByUserId(String userId);
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<AppProfile?> fetchByUserId(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return AppProfile.fromJson(Map<String, dynamic>.from(response as Map));
    } on PostgrestException catch (error) {
      throw StateError('Unable to load profile for $userId: ${error.message}');
    }
  }
}
