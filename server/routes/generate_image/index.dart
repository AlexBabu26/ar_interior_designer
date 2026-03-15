import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

const _nimUrl =
    'https://ai.api.nvidia.com/v1/genai/black-forest-labs/flux.2-klein-4b';

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

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
    final res = await http.post(
      Uri.parse(_nimUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': auth,
      },
      body: body,
    );

    return Response(
      statusCode: res.statusCode,
      body: res.body,
      headers: {
        'Content-Type': 'application/json',
        ..._corsHeaders,
      },
    );
  } catch (e) {
    return Response(
      statusCode: 502,
      body: jsonEncode({'detail': 'Proxy error: $e'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }
}
