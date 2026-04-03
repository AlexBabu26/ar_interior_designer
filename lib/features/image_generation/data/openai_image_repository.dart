import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Result of an OpenAI image edit / generation request.
class OpenAiImageResult {
  const OpenAiImageResult({this.imageBytes, this.error});

  final List<int>? imageBytes;
  final String? error;

  bool get isSuccess => error == null && imageBytes != null;
}

/// Detect image format from magic bytes → MIME subtype (`jpeg`, `png`, `webp`).
String _imageSubtype(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'jpeg';
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'webp';
  }
  return 'png';
}

/// Calls the OpenAI Image Edit API (`/v1/images/edits`) to compose product
/// images into room scenes.  Supports two transport modes:
///
/// * **Proxy** (`proxyUrl` set): sends a JSON payload with base64-encoded
///   images to a local CORS proxy which reconstructs the multipart request
///   server-side.  Required for Flutter web.
/// * **Direct** (`proxyUrl` is null/empty): sends a standard multipart
///   request straight to the OpenAI API.  Works on mobile & desktop.
class OpenAiImageRepository {
  OpenAiImageRepository({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _editUrl = 'https://api.openai.com/v1/images/edits';

  Future<OpenAiImageResult> editImage({
    required String apiKey,
    required String prompt,
    required List<List<int>> images,
    String model = 'gpt-image-1',
    String size = '1024x1024',
    String quality = 'medium',
    String? proxyUrl,
  }) async {
    if (apiKey.trim().isEmpty) {
      return const OpenAiImageResult(error: 'Missing OpenAI API key.');
    }
    if (prompt.trim().isEmpty) {
      return const OpenAiImageResult(error: 'Please enter a prompt.');
    }
    if (images.isEmpty) {
      return const OpenAiImageResult(
        error: 'At least one image is required.',
      );
    }

    try {
      if (proxyUrl != null && proxyUrl.trim().isNotEmpty) {
        return _viaProxy(
          apiKey: apiKey,
          prompt: prompt,
          images: images,
          model: model,
          size: size,
          quality: quality,
          proxyUrl: proxyUrl.trim(),
        );
      }
      return _directMultipart(
        apiKey: apiKey,
        prompt: prompt,
        images: images,
        model: model,
        size: size,
        quality: quality,
      );
    } catch (e) {
      return OpenAiImageResult(error: 'Request failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Proxy mode – sends JSON (base64 images) to the Dart Frog CORS proxy.
  // ---------------------------------------------------------------------------

  Future<OpenAiImageResult> _viaProxy({
    required String apiKey,
    required String prompt,
    required List<List<int>> images,
    required String model,
    required String size,
    required String quality,
    required String proxyUrl,
  }) async {
    final response = await _client.post(
      Uri.parse(proxyUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${apiKey.trim()}',
      },
      body: jsonEncode(<String, dynamic>{
        'prompt': prompt.trim(),
        'model': model,
        'size': size,
        'quality': quality,
        'images': images.map((b) => base64Encode(b)).toList(),
      }),
    );
    return _parseResponse(response.statusCode, response.body);
  }

  // ---------------------------------------------------------------------------
  // Direct mode – standard multipart POST to OpenAI.
  // ---------------------------------------------------------------------------

  Future<OpenAiImageResult> _directMultipart({
    required String apiKey,
    required String prompt,
    required List<List<int>> images,
    required String model,
    required String size,
    required String quality,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_editUrl));
    request.headers['Authorization'] = 'Bearer ${apiKey.trim()}';
    request.fields['model'] = model;
    request.fields['prompt'] = prompt.trim();
    request.fields['size'] = size;
    request.fields['quality'] = quality;

    for (var i = 0; i < images.length; i++) {
      final subtype = _imageSubtype(images[i]);
      final ext = subtype == 'jpeg' ? 'jpg' : subtype;
      request.files.add(
        http.MultipartFile.fromBytes(
          'image[]',
          images[i],
          filename: 'image_$i.$ext',
          contentType: MediaType('image', subtype),
        ),
      );
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    return _parseResponse(streamedResponse.statusCode, responseBody);
  }

  // ---------------------------------------------------------------------------
  // Shared response parser.
  // ---------------------------------------------------------------------------

  OpenAiImageResult _parseResponse(int statusCode, String body) {
    if (statusCode != 200) {
      final decoded = _tryDecode(body) as Map<String, dynamic>?;
      final message = decoded?['error']?['message'] as String? ??
          'API error: $statusCode';
      return OpenAiImageResult(error: message);
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>?;
    if (decoded == null) {
      return const OpenAiImageResult(error: 'Invalid API response.');
    }

    final data = decoded['data'] as List<dynamic>?;
    if (data == null || data.isEmpty) {
      return const OpenAiImageResult(error: 'No image returned.');
    }

    final b64Json =
        (data.first as Map<String, dynamic>)['b64_json'] as String?;
    if (b64Json == null || b64Json.isEmpty) {
      return const OpenAiImageResult(error: 'No image data in response.');
    }

    try {
      return OpenAiImageResult(imageBytes: base64Decode(b64Json));
    } catch (_) {
      return const OpenAiImageResult(error: 'Failed to decode image data.');
    }
  }

  static dynamic _tryDecode(String source) {
    try {
      return jsonDecode(source);
    } catch (_) {
      return null;
    }
  }
}
