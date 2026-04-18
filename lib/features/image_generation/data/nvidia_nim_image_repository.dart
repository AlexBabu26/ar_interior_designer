import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of an NVIDIA NIM image generation request.
class NimImageResult {
  const NimImageResult({this.imageBytes, this.error});

  final List<int>? imageBytes;
  final String? error;

  bool get isSuccess => error == null && imageBytes != null;
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
    );
  }

  // ---------------------------------------------------------------------------

  Future<NimImageResult> _call({
    required String apiKey,
    required String prompt,
    String? proxyUrl,
  }) async {
    if (apiKey.trim().isEmpty) {
      return const NimImageResult(
        error: 'Please enter your NVIDIA NIM API key.',
      );
    }
    if (prompt.trim().isEmpty) {
      return const NimImageResult(error: 'Please enter a text prompt.');
    }

    final url = Uri.parse(
      proxyUrl?.trim().isNotEmpty == true ? proxyUrl!.trim() : baseUrl,
    );
    const width = 1024;
    const height = 1024;
    const steps = 4;
    const seed = 0;
    final body = <String, dynamic>{
      'prompt': prompt.trim(),
      'width': 1024,
      'height': 1024,
      'steps': 4,
      'seed': 0,
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
        String message = 'API error: ${response.statusCode}';
        if (decoded != null) {
          if (decoded['detail'] is String) {
            message = decoded['detail'] as String;
          } else if (decoded['detail'] is List) {
            final details = decoded['detail'] as List;
            if (details.isNotEmpty && details.first is Map) {
               message = details.first['msg']?.toString() ?? details.toString();
            } else {
               message = details.toString();
            }
          } else if (decoded['message'] is String) {
            message = decoded['message'] as String;
          } else {
            message = response.body;
          }
        } else {
           message = response.body;
        }
        return NimImageResult(error: message);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      if (decoded == null) {
        return const NimImageResult(error: 'Invalid API response.');
      }

      final artifacts = decoded['artifacts'] as List<dynamic>?;
      if (artifacts == null || artifacts.isEmpty) {
        return const NimImageResult(error: 'No image returned from the model.');
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
