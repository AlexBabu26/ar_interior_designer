import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_provider.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/storefront/presentation/storefront_screens.dart';

String? resolveAppRedirect({
  required String location,
  String? requestedLocation,
  String? redirectAfterAuth,
  required bool isInitialized,
  required bool isAuthenticated,
  required bool isAdmin,
}) {
  final pendingLocation = requestedLocation ?? location;
  final normalizedRedirect = _normalizeRouteTarget(redirectAfterAuth);
  final preservedDestination = normalizedRedirect ?? pendingLocation;

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
  const protectedRoutes = <String>{'/account', '/cart/checkout', '/admin'};

  if (!isAuthenticated && protectedRoutes.contains(location)) {
    return Uri(
      path: '/login',
      queryParameters: <String, String>{'from': preservedDestination},
    ).toString();
  }

  if (isAuthenticated && guestOnlyRoutes.contains(location)) {
    return normalizedRedirect ?? '/account';
  }

  if (location == '/admin' && !isAdmin) {
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
          return LoginScreen(redirectTo: state.uri.queryParameters['from']);
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
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}

String? _normalizeRouteTarget(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return value;
}
