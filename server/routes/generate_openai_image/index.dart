import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// CORS proxy for the OpenAI Image Edit API.
///
/// Receives a JSON body from the Flutter web client containing base64-encoded
/// images, reconstructs a multipart/form-data request, and forwards it to
/// `https://api.openai.com/v1/images/edits`.  The Authorization header is
/// passed through from the original request.

const _openaiUrl = 'https://api.openai.com/v1/images/edits';

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

/// Detect image format from the first few magic bytes and return the MIME
/// subtype (`jpeg`, `png`, or `webp`).  Falls back to `png`.
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

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204, headers: _corsHeaders);
  }
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: 405,
      body: 'Method Not Allowed',
      headers: _corsHeaders,
    );
  }

  final auth = context.request.headers['authorization'] ??
      context.request.headers['Authorization'];
  if (auth == null || auth.isEmpty) {
    return Response(
      statusCode: 401,
      body: jsonEncode({'detail': 'Missing Authorization header'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }

  final body = await context.request.body();
  if (body.isEmpty) {
    return Response(
      statusCode: 400,
      body: jsonEncode({'detail': 'Empty body'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }

  try {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final prompt = json['prompt'] as String? ?? '';
    final model = json['model'] as String? ?? 'gpt-image-1';
    final size = json['size'] as String? ?? '1024x1024';
    final quality = json['quality'] as String? ?? 'medium';
    final imagesBase64 =
        (json['images'] as List<dynamic>?)?.cast<String>() ?? <String>[];

    if (prompt.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'detail': 'Missing prompt'}),
        headers: {'Content-Type': 'application/json', ..._corsHeaders},
      );
    }
    if (imagesBase64.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'detail': 'At least one image is required'}),
        headers: {'Content-Type': 'application/json', ..._corsHeaders},
      );
    }

    final request = http.MultipartRequest('POST', Uri.parse(_openaiUrl));
    request.headers['Authorization'] = auth;
    request.fields['model'] = model;
    request.fields['prompt'] = prompt;
    request.fields['size'] = size;
    request.fields['quality'] = quality;

    for (var i = 0; i < imagesBase64.length; i++) {
      final imageBytes = base64Decode(imagesBase64[i]);
      final subtype = _imageSubtype(imageBytes);
      final ext = subtype == 'jpeg' ? 'jpg' : subtype;
      request.files.add(
        http.MultipartFile.fromBytes(
          'image[]',
          imageBytes,
          filename: 'image_$i.$ext',
          contentType: MediaType('image', subtype),
        ),
      );
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    return Response(
      statusCode: streamedResponse.statusCode,
      body: responseBody,
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  } catch (e) {
    return Response(
      statusCode: 502,
      body: jsonEncode({'detail': 'Proxy error: $e'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }
}
