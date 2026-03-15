import 'dart:convert';

import 'package:http/http.dart' as http;

/// Default base URL for the upload server (Dart Frog). Run from server/ with `dart_frog dev`.
const String defaultUploadBaseUrl = 'http://localhost:8080';

/// Uploads a 3D model file to the backend; the file is saved under web/product_assets/models.
/// Returns the path to store in DB (e.g. /product_assets/models/xxx.glb).
Future<String> uploadProductModel({
  required List<int> fileBytes,
  required String fileName,
  String baseUrl = defaultUploadBaseUrl,
}) async {
  final uri = Uri.parse('$baseUrl/upload_product_model');
  final request = http.MultipartRequest('POST', uri);
  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ),
  );
  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);
  if (response.statusCode != 200) {
    final body = response.body;
    String message = body;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      message = json['error'] as String? ?? body;
    } catch (_) {}
    throw Exception(message);
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final path = json['path'] as String?;
  if (path == null || path.isEmpty) {
    throw Exception('Server did not return a path');
  }
  return path;
}
