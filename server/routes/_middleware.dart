import 'package:dart_frog/dart_frog.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart' as shelf;

/// Adds CORS headers to every response so the Flutter web app (e.g. localhost:63685)
/// can fetch resources like 3D models from this server (e.g. localhost:8080).
Handler middleware(Handler handler) {
  return handler.use(
    fromShelfMiddleware(
      shelf.corsHeaders(
        headers: {
          shelf.ACCESS_CONTROL_ALLOW_ORIGIN: '*',
          shelf.ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, OPTIONS',
          shelf.ACCESS_CONTROL_ALLOW_HEADERS: 'Content-Type, Authorization',
        },
      ),
    ),
  );
}
