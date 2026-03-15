import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:myapp/features/auth/application/auth_provider.dart';
import 'package:myapp/features/auth/data/auth_gateway.dart';
import 'package:myapp/features/auth/data/profile_repository.dart';
import 'package:myapp/features/auth/domain/app_profile.dart';
import 'package:myapp/features/cart/presentation/cart_provider.dart';
import 'package:myapp/features/catalog/data/product_repository.dart';
import 'package:myapp/features/catalog/domain/product.dart';
import 'package:myapp/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpOverrides? previousHttpOverrides;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = previousHttpOverrides;
  });

  testWidgets('shows the editorial catalog shell for the refreshed app', (
    WidgetTester tester,
  ) async {
    final authProvider = AuthProvider(
      authGateway: _FakeAuthGateway(),
      profileRepository: _FakeProfileRepository(),
    );
    await authProvider.start();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          Provider<ProductRepository>(create: (_) => _FakeProductRepository()),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AR Home'), findsOneWidget);
    expect(find.text('Furniture for the way you live.'), findsOneWidget);
    expect(
      find.text(
        'Curated pieces for calm rooms, tactile materials, and timeless silhouettes.',
      ),
      findsOneWidget,
    );
    expect(find.text('Shop the collection'), findsOneWidget);
    expect(find.text('Smoke Test Chair'), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    expect(find.byTooltip('Toggle theme'), findsNothing);
    expect(find.byIcon(Icons.brightness_6_outlined), findsNothing);
  });

  testWidgets('hero arrow opens the featured product details', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authProvider = AuthProvider(
      authGateway: _FakeAuthGateway(),
      profileRepository: _FakeProfileRepository(),
    );
    await authProvider.start();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          Provider<ProductRepository>(create: (_) => _FakeProductRepository()),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Open featured product'));
    await tester.tap(find.byTooltip('Open featured product'));
    await tester.pumpAndSettle();

    expect(find.text('Product details'), findsOneWidget);
    expect(find.text('Smoke Test Chair'), findsWidgets);
  });
}

class _FakeProductRepository extends ProductRepository {
  static final Product _product = Product(
    id: 'smoke-1',
    name: 'Smoke Test Chair',
    description: 'A deterministic product used for widget smoke tests.',
    price: 199.0,
    imageUrl: 'https://example.com/products/smoke-test-chair.png',
    categories: const ['Chairs'],
    modelUrl: 'https://example.com/models/smoke-test-chair.glb',
  );

  @override
  Future<List<Product>> getProducts() async => [_product];

  @override
  Future<List<Product>> getAdminProducts() async => [_product];

  @override
  Future<Product?> getProductById(String id) async {
    return id == _product.id ? _product : null;
  }

  @override
  Future<String> saveProduct(Product product) async => product.id;

  @override
  Future<void> savePrimaryModel({
    required String productId,
    required String modelUrl,
    String modelType = 'glb',
  }) async {}
}

class _FakeAuthGateway implements AuthGateway {
  @override
  Stream<AuthUserIdentity?> get authStateChanges =>
      const Stream<AuthUserIdentity?>.empty();

  @override
  AuthUserIdentity? get currentUser => null;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> resendSignupVerificationEmail({required String email}) async {}

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {}
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<AppProfile?> fetchByUserId(String userId) async => null;
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Keep widget tests independent from live image requests.
    return _FakeHttpClient();
  }
}

class _FakeHttpClient extends Fake implements HttpClient {
  bool _autoUncompress = true;

  @override
  bool get autoUncompress => _autoUncompress;

  @override
  set autoUncompress(bool value) {
    _autoUncompress = value;
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest();
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState {
    return HttpClientResponseCompressionState.notCompressed;
  }

  @override
  int get statusCode => HttpStatus.ok;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final Uint8List _transparentImage = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4//8/AwAI/AL+KDvK7wAAAABJRU5ErkJggg==',
);
