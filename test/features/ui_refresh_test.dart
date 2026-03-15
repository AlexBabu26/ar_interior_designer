import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:myapp/app/app_theme.dart';
import 'package:myapp/features/admin/presentation/admin_product_screens.dart';
import 'package:myapp/features/catalog/data/product_repository.dart';
import 'package:myapp/features/catalog/domain/product.dart';
import 'package:myapp/features/auth/application/auth_provider.dart';
import 'package:myapp/features/auth/data/auth_gateway.dart';
import 'package:myapp/features/auth/data/profile_repository.dart';
import 'package:myapp/features/auth/domain/app_profile.dart';
import 'package:myapp/features/auth/presentation/auth_screens.dart';
import 'package:myapp/features/orders/data/order_repository.dart';
import 'package:myapp/features/orders/domain/order.dart';
import 'package:myapp/features/orders/domain/order_item.dart';
import 'package:myapp/features/orders/presentation/purchase_history_screen.dart';

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

  testWidgets('login screen uses the refreshed editorial shell', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      authGateway: _GuestAuthGateway(),
      profileRepository: _FakeProfileRepository(),
    );
    await authProvider.start();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text(
        'Sign in to manage purchases, move faster through checkout, and keep your shortlist close at hand.',
      ),
      findsOneWidget,
    );
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets(
    'account and purchase history screens use the refreshed hierarchy',
    (tester) async {
      final authProvider = AuthProvider(
        authGateway: _SignedInAuthGateway(),
        profileRepository: _SignedInProfileRepository(),
      );
      await authProvider.start();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            Provider<OrderRepository>(create: (_) => _FakeOrderRepository()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Column(
              children: [
                Expanded(child: AccountScreen()),
                Expanded(child: PurchaseHistoryScreen()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account overview'), findsOneWidget);
      expect(find.text('Purchase history'), findsOneWidget);
      expect(
        find.text('Every order, gathered in one calm timeline.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('admin product management uses the refreshed workspace layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<ProductRepository>(
        create: (_) => _FakeAdminProductRepository(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AdminProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Collection management'), findsOneWidget);
    expect(
      find.text(
        'Review active products, launch edits, and keep the showroom presentation consistent.',
      ),
      findsOneWidget,
    );
    expect(find.text('Noguchi Table'), findsOneWidget);
  });
}

class _GuestAuthGateway implements AuthGateway {
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

class _SignedInAuthGateway extends _GuestAuthGateway {
  static const AuthUserIdentity _user = AuthUserIdentity(
    id: 'user-1',
    email: 'alex@example.com',
  );

  @override
  AuthUserIdentity? get currentUser => _user;
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<AppProfile?> fetchByUserId(String userId) async => null;
}

class _SignedInProfileRepository implements ProfileRepository {
  @override
  Future<AppProfile?> fetchByUserId(String userId) async {
    return AppProfile(
      id: userId,
      email: 'alex@example.com',
      displayName: 'Alex',
      role: AppProfileRole.customer,
      createdAt: DateTime(2026, 3, 1),
      updatedAt: DateTime(2026, 3, 15),
    );
  }
}

class _FakeOrderRepository implements OrderRepository {
  @override
  Future<void> checkoutActiveCart() async {}

  @override
  Future<List<Order>> getOrders() async {
    return [
      Order(
        id: 'order-1',
        orderNumber: 'ORD-2026-0001',
        status: 'paid',
        subtotal: 1250,
        total: 1250,
        createdAt: DateTime(2026, 3, 15, 10, 30),
        items: const [
          OrderItem(
            id: 'item-1',
            productId: 'chair-1',
            productName: 'Noguchi Table',
            unitPrice: 1250,
            quantity: 1,
            lineTotal: 1250,
          ),
        ],
      ),
    ];
  }
}

class _FakeAdminProductRepository extends ProductRepository {
  static const Product _product = Product(
    id: 'product-1',
    name: 'Noguchi Table',
    description: 'A sculptural table for editorial UI tests.',
    price: 1250,
    imageUrl: 'https://example.com/products/noguchi-table.png',
    categories: ['Tables'],
    modelUrl: 'https://example.com/models/noguchi-table.glb',
  );

  @override
  Future<List<Product>> getAdminProducts() async => [_product];

  @override
  Future<Product?> getProductById(String id) async => _product;

  @override
  Future<List<Product>> getProducts() async => [_product];

  @override
  Future<String> saveProduct(Product product) async => product.id;

  @override
  Future<void> savePrimaryModel({
    required String productId,
    required String modelUrl,
    String modelType = 'glb',
  }) async {}
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
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
