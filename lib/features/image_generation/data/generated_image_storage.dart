import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Saves generated image bytes to app local storage and returns the relative path
/// to store in DB (e.g. "generated_images/<uuid>.png").
Future<String> saveGeneratedImageToLocal(List<int> imageBytes) async {
  final dir = await getApplicationDocumentsDirectory();
  const subDir = 'generated_images';
  final targetDir = Directory('${dir.path}/$subDir');
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }
  const uuid = Uuid();
  final name = '${uuid.v4()}.png';
  final file = File('${targetDir.path}/$name');
  await file.writeAsBytes(imageBytes);
  return '$subDir/$name';
}

/// Resolves the full file path for a stored relative [imagePath].
Future<String> resolveGeneratedImagePath(String imagePath) async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/$imagePath';
}
