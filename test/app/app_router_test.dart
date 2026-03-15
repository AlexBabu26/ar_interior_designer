import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/app/app_router.dart';

void main() {
  group('resolveAppRedirect', () {
    test('redirects guests from checkout to login', () {
      final redirect = resolveAppRedirect(
        location: '/cart/checkout',
        isInitialized: true,
        isAuthenticated: false,
        isAdmin: false,
      );

      expect(redirect, '/login?from=%2Fcart%2Fcheckout');
    });

    test('redirects guests from purchase history to login', () {
      final redirect = resolveAppRedirect(
        location: '/account/purchases',
        isInitialized: true,
        isAuthenticated: false,
        isAdmin: false,
      );

      expect(redirect, '/login?from=%2Faccount%2Fpurchases');
    });

    test('allows guests to keep browsing the catalog', () {
      final redirect = resolveAppRedirect(
        location: '/',
        isInitialized: true,
        isAuthenticated: false,
        isAdmin: false,
      );

      expect(redirect, isNull);
    });

    test('redirects authenticated users away from guest only routes', () {
      final redirect = resolveAppRedirect(
        location: '/login',
        isInitialized: true,
        isAuthenticated: true,
        isAdmin: false,
      );

      expect(redirect, '/account');
    });

    test('preserves checkout destination after login succeeds', () {
      final redirect = resolveAppRedirect(
        location: '/login',
        redirectAfterAuth: '/cart/checkout',
        isInitialized: true,
        isAuthenticated: true,
        isAdmin: false,
      );

      expect(redirect, '/cart/checkout');
    });

    test('redirects non-admin users away from admin routes', () {
      final redirect = resolveAppRedirect(
        location: '/admin',
        isInitialized: true,
        isAuthenticated: true,
        isAdmin: false,
      );

      expect(redirect, '/');
    });

    test('redirects non-admin users away from nested admin routes', () {
      final redirect = resolveAppRedirect(
        location: '/admin/products',
        isInitialized: true,
        isAuthenticated: true,
        isAdmin: false,
      );

      expect(redirect, '/');
    });

    test('sends cold-start deep links through the auth loading route', () {
      final redirect = resolveAppRedirect(
        location: '/admin',
        requestedLocation: '/admin',
        isInitialized: false,
        isAuthenticated: false,
        isAdmin: false,
      );

      expect(redirect, '/auth-loading?from=%2Fadmin');
    });

    test('normalizes absolute callback URLs into app-relative redirects', () {
      final redirect = resolveAppRedirect(
        location: '/login',
        redirectAfterAuth:
            'http://localhost:53503/?error=access_denied&error_code=otp_expired',
        isInitialized: true,
        isAuthenticated: true,
        isAdmin: false,
      );

      expect(redirect, '/?error=access_denied&error_code=otp_expired');
    });

    test('redirects auth callback errors to login with a readable message', () {
      final redirect = resolveAppRedirect(
        location: '/',
        requestedLocation:
            '/?error=access_denied&error_code=otp_expired&error_description=Email%20link%20is%20invalid%20or%20has%20expired',
        isInitialized: true,
        isAuthenticated: false,
        isAdmin: false,
      );

      expect(redirect, '/login?message=Email+link+is+invalid+or+has+expired');
    });
  });
}
