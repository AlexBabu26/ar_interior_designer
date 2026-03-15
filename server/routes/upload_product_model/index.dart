import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

/// Directory relative to server/ where 3D model files are stored.
/// Flutter web serves this as /product_assets/models/
String get _modelsDirectory {
  final current = Directory.current.path;
  final sep = Platform.pathSeparator;
  final parts = current.split(RegExp(r'[/\\]'));
  final root = parts.length > 1 && parts.last == 'server'
      ? parts.sublist(0, parts.length - 1).join(sep)
      : current;
  return '$root${sep}web${sep}product_assets${sep}models';
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

  try {
    final formData = await context.request.formData();
    final files = formData.files;
    final file = files['file'];
    if (file == null) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Missing file. Use form field name: file'}),
        headers: {'Content-Type': 'application/json', ..._corsHeaders},
      );
    }

    final ext = _extension(file.name);
    if (ext.isEmpty || !_allowedExtensions.contains(ext.toLowerCase())) {
      return Response(
        statusCode: 400,
        body: jsonEncode({
          'error': 'Invalid file type. Allowed: ${_allowedExtensions.join(", ")}',
        }),
        headers: {'Content-Type': 'application/json', ..._corsHeaders},
      );
    }

    final bytes = await file.readAsBytes();
    final dir = Directory(_modelsDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final filePath = '${dir.path}${Platform.pathSeparator}$safeName';
    final f = File(filePath);
    await f.writeAsBytes(bytes);

    final pathForDb = '/product_assets/models/$safeName';
    return Response(
      statusCode: 200,
      body: jsonEncode({'path': pathForDb}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  } catch (e, st) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': 'Upload failed: $e'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }
}

String _extension(String name) {
  final i = name.lastIndexOf('.');
  return i < 0 ? '' : name.substring(i);
}

const _allowedExtensions = ['.glb', '.gltf'];
