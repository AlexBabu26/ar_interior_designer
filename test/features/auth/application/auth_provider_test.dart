import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/auth/application/auth_provider.dart';
import 'package:myapp/features/auth/data/auth_gateway.dart';
import 'package:myapp/features/auth/data/profile_repository.dart';
import 'package:myapp/features/auth/domain/app_profile.dart';

void main() {
  group('AuthProvider', () {
    test('start loads the current user profile', () async {
      final authGateway = _FakeAuthGateway(
        initialUser: const AuthUserIdentity(
          id: 'user-1',
          email: 'user@example.com',
        ),
      );
      final profileRepository = _FakeProfileRepository(
        profile: AppProfile(
          id: 'user-1',
          email: 'user@example.com',
          displayName: 'User One',
          role: AppProfileRole.admin,
          createdAt: DateTime.parse('2026-03-15T10:00:00.000Z'),
          updatedAt: DateTime.parse('2026-03-15T10:00:00.000Z'),
        ),
      );

      final provider = AuthProvider(
        authGateway: authGateway,
        profileRepository: profileRepository,
      );

      await provider.start();

      expect(provider.isInitialized, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.email, 'user@example.com');
      expect(provider.profile?.displayName, 'User One');
      expect(provider.isAdmin, isTrue);
    });

    test('signIn and signOut update the auth state', () async {
      final authGateway = _FakeAuthGateway();
      final profileRepository = _FakeProfileRepository(
        profile: AppProfile(
          id: 'user-2',
          email: 'customer@example.com',
          displayName: 'Customer',
          role: AppProfileRole.customer,
          createdAt: DateTime.parse('2026-03-15T10:00:00.000Z'),
          updatedAt: DateTime.parse('2026-03-15T10:00:00.000Z'),
        ),
      );

      final provider = AuthProvider(
        authGateway: authGateway,
        profileRepository: profileRepository,
      );
      await provider.start();

      final didSignIn = await provider.signIn(
        email: 'customer@example.com',
        password: 'password-123',
      );

      expect(didSignIn, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.email, 'customer@example.com');
      expect(provider.profile?.role, AppProfileRole.customer);

      await provider.signOut();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
      expect(provider.profile, isNull);
    });

    test('stores a user friendly error message when sign in fails', () async {
      final authGateway = _FakeAuthGateway(shouldThrowOnSignIn: true);
      final provider = AuthProvider(
        authGateway: authGateway,
        profileRepository: _FakeProfileRepository(),
      );
      await provider.start();

      final didSignIn = await provider.signIn(
        email: 'fail@example.com',
        password: 'wrong-password',
      );

      expect(didSignIn, isFalse);
      expect(provider.errorMessage, contains('Invalid email or password'));
      expect(provider.isAuthenticated, isFalse);
    });

    test('ignores stale profile loads after a later sign out', () async {
      final delayedRepository = _DelayedProfileRepository();
      final authGateway = _FakeAuthGateway(
        initialUser: const AuthUserIdentity(
          id: 'user-1',
          email: 'user@example.com',
        ),
      );
      final provider = AuthProvider(
        authGateway: authGateway,
        profileRepository: delayedRepository,
      );

      final startFuture = provider.start();
      await Future<void>.delayed(Duration.zero);

      authGateway.emit(null);
      await Future<void>.delayed(Duration.zero);

      delayedRepository.complete(
        'user-1',
        AppProfile(
          id: 'user-1',
          email: 'user@example.com',
          displayName: 'Stale User',
          role: AppProfileRole.admin,
          createdAt: DateTime.parse('2026-03-15T10:00:00.000Z'),
          updatedAt: DateTime.parse('2026-03-15T10:00:00.000Z'),
        ),
      );

      await startFuture;
      await Future<void>.delayed(Duration.zero);

      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
      expect(provider.profile, isNull);
      expect(provider.isAdmin, isFalse);
    });

    test('still initializes when profile loading fails', () async {
      final authGateway = _FakeAuthGateway(
        initialUser: const AuthUserIdentity(
          id: 'user-4',
          email: 'broken@example.com',
        ),
      );
      final provider = AuthProvider(
        authGateway: authGateway,
        profileRepository: _ThrowingProfileRepository(),
      );

      await provider.start();

      expect(provider.isInitialized, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.email, 'broken@example.com');
      expect(provider.profile, isNull);
      expect(provider.errorMessage, contains('Profile load failed'));
    });

    test('stores an error message when sign out fails', () async {
      final provider = AuthProvider(
        authGateway: _FakeAuthGateway(
          initialUser: const AuthUserIdentity(
            id: 'user-5',
            email: 'stuck@example.com',
          ),
          shouldThrowOnSignOut: true,
        ),
        profileRepository: _FakeProfileRepository(),
      );

      await provider.start();

      final didSignOut = await provider.signOut();

      expect(didSignOut, isFalse);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.errorMessage, contains('Unable to sign out'));
    });

    test('resends verification email and stores a success message', () async {
      final authGateway = _FakeAuthGateway();
      final provider = AuthProvider(
        authGateway: authGateway,
        profileRepository: _FakeProfileRepository(),
      );
      await provider.start();

      final didResend = await provider.resendVerificationEmail(
        email: 'pending@example.com',
      );

      expect(didResend, isTrue);
      expect(authGateway.lastResendVerificationEmail, 'pending@example.com');
      expect(
        provider.infoMessage,
        contains('verification email has been sent'),
      );
    });
  });
}

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({
    this.initialUser,
    this.shouldThrowOnSignIn = false,
    this.shouldThrowOnSignOut = false,
  }) : _currentUser = initialUser;

  final AuthUserIdentity? initialUser;
  final bool shouldThrowOnSignIn;
  final bool shouldThrowOnSignOut;
  String? lastResendVerificationEmail;
  final StreamController<AuthUserIdentity?> _controller =
      StreamController<AuthUserIdentity?>.broadcast();

  AuthUserIdentity? _currentUser;

  @override
  Stream<AuthUserIdentity?> get authStateChanges => _controller.stream;

  @override
  AuthUserIdentity? get currentUser => _currentUser;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> resendSignupVerificationEmail({required String email}) async {
    lastResendVerificationEmail = email;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (shouldThrowOnSignIn) {
      throw const AuthGatewayException('Invalid email or password.');
    }

    _currentUser = AuthUserIdentity(id: 'user-2', email: email);
    _controller.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    if (shouldThrowOnSignOut) {
      throw const AuthGatewayException('Unable to sign out right now.');
    }

    _currentUser = null;
    _controller.add(null);
  }

  void emit(AuthUserIdentity? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _currentUser = AuthUserIdentity(id: 'user-3', email: email);
    _controller.add(_currentUser);
  }
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({this.profile});

  final AppProfile? profile;

  @override
  Future<AppProfile?> fetchByUserId(String userId) async => profile;
}

class _DelayedProfileRepository implements ProfileRepository {
  final Map<String, Completer<AppProfile?>> _completers =
      <String, Completer<AppProfile?>>{};

  @override
  Future<AppProfile?> fetchByUserId(String userId) {
    return _completers.putIfAbsent(userId, Completer<AppProfile?>.new).future;
  }

  void complete(String userId, AppProfile? profile) {
    _completers
        .putIfAbsent(userId, Completer<AppProfile?>.new)
        .complete(profile);
  }
}

class _ThrowingProfileRepository implements ProfileRepository {
  @override
  Future<AppProfile?> fetchByUserId(String userId) async {
    throw StateError('Profile load failed.');
  }
}
