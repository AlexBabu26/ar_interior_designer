import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

/// Directory relative to server/ where 3D model files are stored (same as upload route).
String get _modelsDirectory {
  final current = Directory.current.path;
  final sep = Platform.pathSeparator;
  final parts = current.split(RegExp(r'[/\\]'));
  final root = parts.length > 1 && parts.last == 'server'
      ? parts.sublist(0, parts.length - 1).join(sep)
      : current;
  return '$root${sep}web${sep}product_assets${sep}models';
}

const _allowedExtensions = ['.glb', '.gltf'];

Future<Response> onRequest(RequestContext context, String filename) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204, headers: _corsHeaders);
  }
  if (context.request.method != HttpMethod.get) {
    return Response(
      statusCode: 405,
      body: 'Method Not Allowed',
      headers: _corsHeaders,
    );
  }

  if (filename.isEmpty || filename.contains('..') || filename.contains('/')) {
    return Response(
      statusCode: 400,
      body: 'Invalid filename',
      headers: _corsHeaders,
    );
  }

  final ext = filename.toLowerCase().endsWith('.gltf')
      ? '.gltf'
      : (filename.toLowerCase().endsWith('.glb') ? '.glb' : '');
  if (!_allowedExtensions.contains(ext)) {
    return Response(
      statusCode: 400,
      body: 'Allowed: .glb, .gltf',
      headers: _corsHeaders,
    );
  }

  final file = File('${_modelsDirectory}${Platform.pathSeparator}$filename');
  if (!await file.exists()) {
    return Response(
      statusCode: 404,
      body: 'Not found',
      headers: _corsHeaders,
    );
  }

  final bytes = await file.readAsBytes();
  final contentType = ext == '.gltf' ? 'model/gltf+json' : 'model/gltf-binary';

  return Response.bytes(
    statusCode: 200,
    body: bytes,
    headers: {
      'Content-Type': contentType,
      'Content-Length': bytes.length.toString(),
      ..._corsHeaders,
    },
  );
}
