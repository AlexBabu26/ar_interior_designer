import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of an NVIDIA NIM image generation request.
class NimImageResult {
  const NimImageResult({
    this.imageBytes,
    this.error,
  });

  final List<int>? imageBytes;
  final String? error;

  bool get isSuccess => error == null && imageBytes != null;
}

/// Detect image MIME subtype from magic bytes.
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

/// Converts raw image bytes into a `data:image/…;base64,…` URI that the
/// NVIDIA NIM API accepts in the `image` array field.
String _toDataUri(List<int> bytes) {
  final subtype = _imageSubtype(bytes);
  return 'data:image/$subtype;base64,${base64Encode(bytes)}';
}

/// Calls the NVIDIA NIM Visual Models API (Flux 2 Klein) to generate an image.
/// See: https://docs.api.nvidia.com/nim/reference/visual-models-apis
class NvidiaNimImageRepository {
  NvidiaNimImageRepository({
    this.baseUrl =
        'https://ai.api.nvidia.com/v1/genai/black-forest-labs/flux.2-klein-4b',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// Generates an image from [prompt] using [apiKey].
  /// Uses 1024x1024, steps=4, seed=0. Pass [proxyUrl] to avoid CORS on web
  /// (your backend forwards the request to the NVIDIA API).
  Future<NimImageResult> generateImage({
    required String apiKey,
    required String prompt,
    String? proxyUrl,
  }) async {
    return _call(apiKey: apiKey, prompt: prompt, proxyUrl: proxyUrl);
  }

  /// Image-to-image editing: sends one or more reference [images] (raw bytes)
  /// alongside a [prompt].  The images are encoded as data-URIs and passed in
  /// the `"image"` field that the Flux model accepts.
  Future<NimImageResult> editImage({
    required String apiKey,
    required String prompt,
    required List<List<int>> images,
    String? proxyUrl,
  }) async {
    if (images.isEmpty) {
      return const NimImageResult(
        error: 'At least one reference image is required.',
      );
    }
    return _call(
      apiKey: apiKey,
      prompt: prompt,
      proxyUrl: proxyUrl,
      imageDataUris: images.map(_toDataUri).toList(),
    );
  }

  // ---------------------------------------------------------------------------

  Future<NimImageResult> _call({
    required String apiKey,
    required String prompt,
    String? proxyUrl,
    List<String>? imageDataUris,
  }) async {
    if (apiKey.trim().isEmpty) {
      return const NimImageResult(
        error: 'Please enter your NVIDIA NIM API key.',
      );
    }
    if (prompt.trim().isEmpty) {
      return const NimImageResult(
        error: 'Please enter a text prompt.',
      );
    }

    final url = Uri.parse(
      proxyUrl?.trim().isNotEmpty == true ? proxyUrl!.trim() : baseUrl,
    );
    final body = <String, dynamic>{
      'prompt': prompt.trim(),
      'width': 1024,
      'height': 1024,
      'steps': 4,
      'seed': 0,
      if (imageDataUris != null && imageDataUris.isNotEmpty)
        'image': imageDataUris,
    };

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${apiKey.trim()}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final decoded = _tryDecode(response.body) as Map<String, dynamic>?;
        final message = decoded?['detail'] as String? ??
            decoded?['message'] as String? ??
            'API error: ${response.statusCode}';
        return NimImageResult(error: message);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      if (decoded == null) {
        return const NimImageResult(error: 'Invalid API response.');
      }

      final artifacts = decoded['artifacts'] as List<dynamic>?;
      if (artifacts == null || artifacts.isEmpty) {
        return const NimImageResult(
          error: 'No image returned from the model.',
        );
      }

      final first = artifacts.first as Map<String, dynamic>?;
      final b64 = first?['base64'] as String?;
      if (b64 == null || b64.isEmpty) {
        return const NimImageResult(
          error: 'Model did not return valid image data.',
        );
      }

      try {
        return NimImageResult(imageBytes: base64Decode(b64));
      } catch (_) {
        return const NimImageResult(error: 'Failed to decode image.');
      }
    } catch (e) {
      return NimImageResult(error: 'Request failed: $e');
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
