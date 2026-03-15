import 'package:supabase_flutter/supabase_flutter.dart';

class AuthUserIdentity {
  const AuthUserIdentity({required this.id, required this.email});

  final String id;
  final String email;
}

class AuthGatewayException implements Exception {
  const AuthGatewayException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthGateway {
  Stream<AuthUserIdentity?> get authStateChanges;

  AuthUserIdentity? get currentUser;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> resendSignupVerificationEmail({required String email});

  Future<void> signOut();
}

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Stream<AuthUserIdentity?> get authStateChanges {
    return _client.auth.onAuthStateChange.map(
      (data) => _mapUser(data.session?.user ?? _client.auth.currentUser),
    );
  }

  @override
  AuthUserIdentity? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (error) {
      throw AuthGatewayException(error.message);
    }
  }

  @override
  Future<void> resendSignupVerificationEmail({required String email}) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } on AuthException catch (error) {
      throw AuthGatewayException(error.message);
    }
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw AuthGatewayException(error.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AuthGatewayException(error.message);
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{
          if (displayName != null && displayName.trim().isNotEmpty)
            'display_name': displayName.trim(),
        },
      );
    } on AuthException catch (error) {
      throw AuthGatewayException(error.message);
    }
  }

  AuthUserIdentity? _mapUser(User? user) {
    if (user == null) {
      return null;
    }

    return AuthUserIdentity(id: user.id, email: user.email ?? '');
  }
}
