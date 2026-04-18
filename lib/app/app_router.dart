import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_analytics_screen.dart';
import '../features/admin/presentation/admin_category_screen.dart';
import '../features/admin/presentation/admin_create_carpenter_screen.dart';
import '../features/admin/presentation/admin_inventory_screen.dart';
import '../features/admin/presentation/admin_product_screens.dart';
import '../features/auth/application/auth_provider.dart';
import '../features/cart/presentation/cart_provider.dart';
import '../features/cart/presentation/order_success_screen.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/image_generation/presentation/generations_history_screen.dart';
import '../features/modifications/presentation/modification_chat_screen.dart';
import '../features/modifications/presentation/modification_list_screen.dart';
import '../features/orders/presentation/purchase_history_screen.dart';
import '../features/storefront/presentation/ar_scene_screen_stub.dart'
    if (dart.library.io) '../features/storefront/presentation/ar_scene_screen.dart';
import '../features/storefront/presentation/staging_screen.dart';
import '../features/storefront/presentation/storefront_screens.dart';
import '../app/widgets/main_layout.dart';
import '../features/storefront/presentation/home_screen.dart';
import '../features/storefront/presentation/ai_room_screen.dart';

String? resolveAppRedirect({
  required String location,
  required bool isInitialized,
  required bool isAuthenticated,
  required bool isAdmin,
  bool isCarpenter = false,
  String? requestedLocation,
  String? redirectAfterAuth,
}) {
  final pendingLocation = _normalizeRouteTarget(requestedLocation) ?? location;
  final requestedUri = Uri.tryParse(requestedLocation ?? pendingLocation);
  final authErrorDescription =
      requestedUri?.queryParameters['error_description'];
  final normalizedRedirect = _normalizeRouteTarget(redirectAfterAuth);
  final preservedDestination = normalizedRedirect ?? pendingLocation;

  if (authErrorDescription != null && authErrorDescription.isNotEmpty) {
    return Uri(
      path: '/login',
      queryParameters: <String, String>{'message': authErrorDescription},
    ).toString();
  }

  if (!isInitialized) {
    if (location == '/auth-loading') {
      return null;
    }

    return Uri(
      path: '/auth-loading',
      queryParameters: <String, String>{'from': preservedDestination},
    ).toString();
  }

  if (location == '/auth-loading') {
    final destination = preservedDestination.isEmpty ? '/' : preservedDestination;
    final finalDest = destination == '/auth-loading' ? '/' : destination;
    
    if (finalDest == '/') {
      if (isAdmin) return '/admin';
      if (isCarpenter) return '/carpenter';
    }
    return finalDest;
  }

  const guestOnlyRoutes = <String>{
    '/welcome',
    '/login',
    '/signup',
    '/register',
    '/forgot-password',
  };
  final requiresAuth =
      location == '/account' ||
      location.startsWith('/account/') ||
      location == '/cart/checkout' ||
      location == '/admin' ||
      location.startsWith('/admin/') ||
      location == '/carpenter' ||
      location.startsWith('/carpenter/');

  if (!isAuthenticated && requiresAuth) {
    return Uri(
      path: '/welcome',
      queryParameters: <String, String>{'from': preservedDestination},
    ).toString();
  }

  if (isAuthenticated && guestOnlyRoutes.contains(location)) {
    final target = normalizedRedirect ?? '/';
    if (target == '/') {
      if (isAdmin) return '/admin';
      if (isCarpenter) return '/carpenter';
    }
    return target;
  }

  if (!isAuthenticated && location == '/') {
    return '/welcome';
  }

  if (isAuthenticated && location == '/') {
    if (isAdmin) return '/admin';
    if (isCarpenter) return '/carpenter';
  }

  if ((location == '/admin' || location.startsWith('/admin/')) && !isAdmin) {
    return '/';
  }

  if (isCarpenter &&
      (location == '/account/purchases' || location == '/account/generations')) {
    return '/account';
  }

  return null;
}

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: authProvider,
    redirect: (context, state) {
      return resolveAppRedirect(
        location: state.matchedLocation,
        requestedLocation: state.uri.toString(),
        redirectAfterAuth: state.uri.queryParameters['from'],
        isInitialized: authProvider.isInitialized,
        isAuthenticated: authProvider.isAuthenticated,
        isAdmin: authProvider.isAdmin,
        isCarpenter: authProvider.isCarpenter,
      );
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(state: state, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/catalog',
            builder: (context, state) => const CatalogScreen(),
            routes: [
              GoRoute(
                path: 'product/:id',
                builder: (context, state) => ProductDetailScreen(
                  productId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/ai-room',
            builder: (context, state) => const AIRoomScreen(),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
            routes: [
              GoRoute(
                path: 'checkout',
                builder: (context, state) => const CheckoutScreen(),
              ),
              GoRoute(
                path: 'success/:id',
                builder: (context, state) => OrderSuccessScreen(
                  orderId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/account',
            builder: (context, state) => const AccountScreen(),
            routes: [
              GoRoute(
                path: 'purchases',
                builder: (context, state) => const PurchaseHistoryScreen(),
              ),
              GoRoute(
                path: 'generations',
                builder: (context, state) => const GenerationsHistoryScreen(),
              ),
              GoRoute(
                path: 'modifications',
                builder: (context, state) => ModificationListScreen(
                  productId: state.uri.queryParameters['productId'],
                  history: state.uri.queryParameters['history'] == 'true',
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ModificationChatScreen(
                      modificationId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Auth and AR routes remain outside ShellRoute for full-screen feel.
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth-loading',
        builder: (context, state) => AuthLoadingScreen(
          redirectTo: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          redirectTo: state.uri.queryParameters['from'],
          message: state.uri.queryParameters['message'],
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => RegisterScreen(
          redirectTo: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordScreen(
          redirectTo: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: '/ar/:id',
        builder: (context, state) => ARViewScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/ar-scene',
        builder: (context, state) => ARSceneScreen(
          initialProductId: state.uri.queryParameters['product'],
        ),
      ),
      GoRoute(
        path: '/staging',
        builder: (context, state) => StagingScreen(
          initialProductId: state.uri.queryParameters['product'],
        ),
      ),
      GoRoute(
        path: '/carpenter',
        builder: (context, state) => const CarpenterDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'create-carpenter',
            builder: (context, state) => const AdminCreateCarpenterScreen(),
          ),
          GoRoute(
            path: 'modifications',
            builder: (context, state) => const ModificationListScreen(),
          ),
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AdminAnalyticsScreen(),
          ),
          GoRoute(
            path: 'categories',
            builder: (context, state) => const AdminCategoryScreen(),
          ),
          GoRoute(
            path: 'products',
            builder: (context, state) => const AdminProductsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const AdminProductFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => AdminProductFormScreen(
                  productId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'inventory',
            builder: (context, state) => const AdminInventoryScreen(),
          ),
        ],
      ),
    ],
  );
}

String? _normalizeRouteTarget(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final parsed = Uri.tryParse(value);
  if (parsed == null) {
    return value.startsWith('/') ? value : '/';
  }

  final path = parsed.path.isEmpty ? '/' : parsed.path;
  final normalized = Uri(
    path: path,
    queryParameters: parsed.queryParameters.isEmpty
        ? null
        : parsed.queryParameters,
    fragment: parsed.fragment.isEmpty ? null : parsed.fragment,
  ).toString();

  return normalized.startsWith('/') ? normalized : '/$normalized';
}
