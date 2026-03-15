import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_analytics_screen.dart';
import '../features/admin/presentation/admin_product_screens.dart';
import '../features/auth/application/auth_provider.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/image_generation/presentation/generations_history_screen.dart';
import '../features/orders/presentation/purchase_history_screen.dart';
import '../features/storefront/presentation/storefront_screens.dart';

String? resolveAppRedirect({
  required String location,
  String? requestedLocation,
  String? redirectAfterAuth,
  required bool isInitialized,
  required bool isAuthenticated,
  required bool isAdmin,
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
    final destination = preservedDestination.isEmpty
        ? '/'
        : preservedDestination;
    return destination == '/auth-loading' ? '/' : destination;
  }

  const guestOnlyRoutes = <String>{'/login', '/register', '/forgot-password'};
  final requiresAuth =
      location == '/account' ||
      location.startsWith('/account/') ||
      location == '/cart/checkout' ||
      location == '/admin' ||
      location.startsWith('/admin/');

  if (!isAuthenticated && requiresAuth) {
    return Uri(
      path: '/login',
      queryParameters: <String, String>{'from': preservedDestination},
    ).toString();
  }

  if (isAuthenticated && guestOnlyRoutes.contains(location)) {
    return normalizedRedirect ?? '/account';
  }

  if ((location == '/admin' || location.startsWith('/admin/')) && !isAdmin) {
    return '/';
  }

  return null;
}

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      return resolveAppRedirect(
        location: state.matchedLocation,
        requestedLocation: state.uri.toString(),
        redirectAfterAuth: state.uri.queryParameters['from'],
        isInitialized: authProvider.isInitialized,
        isAuthenticated: authProvider.isAuthenticated,
        isAdmin: authProvider.isAdmin,
      );
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CatalogScreen(),
        routes: [
          GoRoute(
            path: 'product/:id',
            builder: (context, state) {
              return ProductDetailScreen(
                productId: state.pathParameters['id']!,
              );
            },
          ),
          GoRoute(
            path: 'ar/:id',
            builder: (context, state) {
              return ARViewScreen(productId: state.pathParameters['id']!);
            },
          ),
          GoRoute(
            path: 'cart',
            builder: (context, state) => const CartScreen(),
            routes: [
              GoRoute(
                path: 'checkout',
                builder: (context, state) => const CheckoutScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/auth-loading',
        builder: (context, state) {
          return AuthLoadingScreen(
            redirectTo: state.uri.queryParameters['from'],
          );
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return LoginScreen(
            redirectTo: state.uri.queryParameters['from'],
            message: state.uri.queryParameters['message'],
          );
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          return RegisterScreen(redirectTo: state.uri.queryParameters['from']);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          return ForgotPasswordScreen(
            redirectTo: state.uri.queryParameters['from'],
          );
        },
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
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AdminAnalyticsScreen(),
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
