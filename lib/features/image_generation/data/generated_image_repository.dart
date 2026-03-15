import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/generated_image.dart';

abstract class GeneratedImageRepository {
  Future<List<GeneratedImage>> getByUserId(String userId);
  Future<GeneratedImage?> insert({
    required String userId,
    required String prompt,
    required String imagePath,
  });
}

class SupabaseGeneratedImageRepository implements GeneratedImageRepository {
  SupabaseGeneratedImageRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<GeneratedImage>> getByUserId(String userId) async {
    final response = await _client
        .from('generated_images')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => GeneratedImage.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<GeneratedImage?> insert({
    required String userId,
    required String prompt,
    required String imagePath,
  }) async {
    final response = await _client.from('generated_images').insert({
      'user_id': userId,
      'prompt': prompt,
      'image_path': imagePath,
    }).select().single();

    return GeneratedImage.fromJson(Map<String, dynamic>.from(response as Map));
  }
}
