import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const _bucket = 'generated-images';

/// Uploads generated image bytes to Supabase Storage and returns the storage
/// path to store in DB (e.g. "userId/uuid.png"). Works on web and all platforms.
Future<String> saveGeneratedImageToStorage(
  String userId,
  List<int> imageBytes,
) async {
  const uuid = Uuid();
  final path = '$userId/${uuid.v4()}.png';
  await Supabase.instance.client.storage.from(_bucket).uploadBinary(
        path,
        Uint8List.fromList(imageBytes),
        fileOptions: const FileOptions(upsert: true),
      );
  return path;
}

/// Returns the public URL for a stored image path (from DB).
String getGeneratedImageUrl(String imagePath) {
  return Supabase.instance.client.storage.from(_bucket).getPublicUrl(imagePath);
}
