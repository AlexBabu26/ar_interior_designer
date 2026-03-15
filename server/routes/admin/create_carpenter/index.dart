import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

/// Load env from Platform.environment, with fallback to server/.env file.
Map<String, String> _loadEnv() {
  final map = Map<String, String>.from(Platform.environment);
  if (map['SUPABASE_URL'] != null &&
      map['SUPABASE_URL']!.isNotEmpty &&
      map['SUPABASE_SERVICE_ROLE_KEY'] != null &&
      map['SUPABASE_SERVICE_ROLE_KEY']!.isNotEmpty) {
    return map;
  }
  final envFile = File('.env');
  if (!envFile.existsSync()) return map;
  for (final line in envFile.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final eq = trimmed.indexOf('=');
    if (eq <= 0) continue;
    final key = trimmed.substring(0, eq).trim();
    var value = trimmed.substring(eq + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    map[key] = value;
  }
  return map;
}

/// Decodes JWT payload (no verification; used to get admin user id from session token).
String? _decodeJwtSub(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    var payload = parts[1];
    switch (payload.length % 4) {
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }
    final decoded = utf8.decode(base64Url.decode(payload));
    final map = jsonDecode(decoded) as Map<String, dynamic>;
    return map['sub'] as String?;
  } catch (_) {
    return null;
  }
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

  final authHeader =
      context.request.headers['authorization'] ??
      context.request.headers['Authorization'];
  if (authHeader == null ||
      authHeader.isEmpty ||
      !authHeader.toLowerCase().startsWith('bearer ')) {
    return Response(
      statusCode: 401,
      body: jsonEncode({'error': 'Missing or invalid Authorization header'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }

  final env = _loadEnv();
  final supabaseUrl = env['SUPABASE_URL'] ?? '';
  final serviceRoleKey = env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  if (supabaseUrl.isEmpty || serviceRoleKey.isEmpty) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': 'Server not configured for admin user creation'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }

  final bearerToken = authHeader.substring(7).trim();
  final adminUserId = _decodeJwtSub(bearerToken);
  if (adminUserId == null) {
    return Response(
      statusCode: 401,
      body: jsonEncode({'error': 'Invalid token'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }

  // Verify requestor is admin
  final profileRes = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$adminUserId&select=role'),
    headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
      'Content-Type': 'application/json',
    },
  );
  if (profileRes.statusCode != 200) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': 'Failed to verify admin'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }
  final profileList = jsonDecode(profileRes.body) as List<dynamic>;
  if (profileList.isEmpty) {
    return Response(
      statusCode: 403,
      body: jsonEncode({'error': 'Profile not found'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }
  final role = (profileList.first as Map<String, dynamic>)['role'] as String?;
  if (role != 'admin') {
    return Response(
      statusCode: 403,
      body: jsonEncode({'error': 'Only admins can create carpenter accounts'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }

  final body = await context.request.body();
  if (body.isEmpty) {
    return Response(
      statusCode: 400,
      body: jsonEncode({'error': 'Body required'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }
  Map<String, dynamic> json;
  try {
    json = jsonDecode(body) as Map<String, dynamic>;
  } catch (_) {
    return Response(
      statusCode: 400,
      body: jsonEncode({'error': 'Invalid JSON'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }
  final email = (json['email'] as String?)?.trim();
  final password = json['password'] as String?;
  final displayName = (json['display_name'] as String?)?.trim();
  if (email == null || email.isEmpty || password == null || password.isEmpty) {
    return Response(
      statusCode: 400,
      body: jsonEncode({'error': 'email and password are required'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }

  // Create user via Supabase Auth Admin API
  final createRes = await http.post(
    Uri.parse('$supabaseUrl/auth/v1/admin/users'),
    headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': password,
      'email_confirm': true,
      if (displayName != null && displayName.isNotEmpty)
        'user_metadata': {'display_name': displayName},
    }),
  );

  if (createRes.statusCode != 200 && createRes.statusCode != 201) {
    final errBody = createRes.body;
    String message = 'Failed to create user';
    try {
      final errJson = jsonDecode(errBody) as Map<String, dynamic>;
      message = errJson['msg'] as String? ??
          errJson['message'] as String? ??
          errBody;
    } catch (_) {}
    return Response(
      statusCode: createRes.statusCode,
      body: jsonEncode({'error': message}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }

  final userJson = jsonDecode(createRes.body) as Map<String, dynamic>;
  final newUserId = userJson['id'] as String?;
  if (newUserId == null) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': 'User created but id not returned'}),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }

  // Set profile role to carpenter (trigger created profile with role=customer)
  final updateRes = await http.patch(
    Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$newUserId'),
    headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
      'Content-Type': 'application/json',
      'Prefer': 'return=minimal',
    },
    body: jsonEncode({
      'role': 'carpenter',
      if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
    }),
  );

  if (updateRes.statusCode != 200 && updateRes.statusCode != 204) {
    return Response(
      statusCode: 500,
      body: jsonEncode({
        'error': 'User created but failed to set carpenter role',
        'user_id': newUserId,
      }),
      headers: {'Content-Type': 'application/json', ..._corsHeaders},
    );
  }

  return Response(
    statusCode: 201,
    body: jsonEncode({
      'id': newUserId,
      'email': userJson['email'] as String? ?? email,
    }),
    headers: {'Content-Type': 'application/json', ..._corsHeaders},
  );
}
