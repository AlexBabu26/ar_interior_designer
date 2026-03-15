import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of a Gemini image generation request.
class GeminiImageResult {
  const GeminiImageResult({
    this.imageBytes,
    this.text,
    this.error,
  });

  final List<int>? imageBytes;
  final String? text;
  final String? error;

  bool get isSuccess => error == null && (imageBytes != null || text != null);
}

/// Calls the Gemini API (REST) to generate an image from a text prompt.
/// Uses the native image generation model and returns the first image part.
class GeminiImageRepository {
  GeminiImageRepository({
    this.modelId = 'gemini-2.0-flash-preview-image-generation',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String modelId;
  final http.Client _client;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Generates an image from [prompt] using [apiKey].
  /// Returns image bytes (PNG) if the model returns an image part.
  Future<GeminiImageResult> generateImage({
    required String apiKey,
    required String prompt,
  }) async {
    if (apiKey.trim().isEmpty) {
      return const GeminiImageResult(
        error: 'Please enter your Gemini API key.',
      );
    }
    if (prompt.trim().isEmpty) {
      return const GeminiImageResult(
        error: 'Please enter a text prompt.',
      );
    }

    final url = Uri.parse('$_baseUrl/$modelId:generateContent');
    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt.trim()}
          ]
        }
      ],
      'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE'],
      },
    };

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey.trim(),
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final decoded =
            _tryDecode(response.body) as Map<String, dynamic>?;
        final message = decoded?['error']?['message'] as String? ??
            'API error: ${response.statusCode}';
        return GeminiImageResult(error: message);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      if (decoded == null) {
        return const GeminiImageResult(error: 'Invalid API response.');
      }

      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        final promptFeedback = decoded['promptFeedback'] as Map<String, dynamic>?;
        final blockReason = promptFeedback?['blockReason'] as String?;
        if (blockReason != null) {
          return GeminiImageResult(
            error: 'Content was blocked: $blockReason',
          );
        }
        return const GeminiImageResult(
          error: 'No response from the model. Try a different prompt.',
        );
      }

      final content = candidates.first as Map<String, dynamic>?;
      final parts = content?['content']?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return const GeminiImageResult(
          error: 'Empty response from the model.',
        );
      }

      List<int>? imageBytes;
      String? text;

      for (final part in parts) {
        final map = part as Map<String, dynamic>?;
        if (map == null) continue;
        if (map.containsKey('inlineData')) {
          final data = map['inlineData'] as Map<String, dynamic>?;
          final base64 = data?['data'] as String?;
          if (base64 != null && base64.isNotEmpty) {
            try {
              imageBytes = base64Decode(base64);
              break;
            } catch (_) {
              // skip invalid base64
            }
          }
        }
        if (map.containsKey('text')) {
          text = map['text'] as String?;
        }
      }

      if (imageBytes != null) {
        return GeminiImageResult(imageBytes: imageBytes, text: text);
      }
      if (text != null && text.isNotEmpty) {
        return GeminiImageResult(
          text: text,
          error: 'Model returned text but no image. Try a different prompt.',
        );
      }
      return const GeminiImageResult(
        error: 'Model did not return an image. Try a different prompt.',
      );
    } catch (e) {
      return GeminiImageResult(
        error: 'Request failed: $e',
      );
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
