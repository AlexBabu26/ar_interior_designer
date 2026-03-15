import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_gateway.dart';
import '../data/profile_repository.dart';
import '../domain/app_profile.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider({
    required AuthGateway authGateway,
    required ProfileRepository profileRepository,
  }) : _authGateway = authGateway,
       _profileRepository = profileRepository;

  final AuthGateway _authGateway;
  final ProfileRepository _profileRepository;

  StreamSubscription<AuthUserIdentity?>? _authSubscription;
  AuthUserIdentity? _currentUser;
  AppProfile? _profile;
  bool _isInitialized = false;
  bool _isBusy = false;
  int _syncVersion = 0;
  String? _errorMessage;
  String? _infoMessage;

  AuthUserIdentity? get currentUser => _currentUser;
  AppProfile? get profile => _profile;
  bool get isInitialized => _isInitialized;
  bool get isBusy => _isBusy;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _profile?.isAdmin ?? false;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;

  Future<void> start() async {
    if (_authSubscription != null) {
      return;
    }

    _authSubscription = _authGateway.authStateChanges.listen((user) {
      unawaited(_syncFromUser(user));
    });

    await _syncFromUser(_authGateway.currentUser);
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    return _runAuthAction(() async {
      await _authGateway.sendPasswordResetEmail(email: email.trim());
      _infoMessage =
          'If an account exists for that email, a reset link has been sent.';
    });
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _runAuthAction(() async {
      await _authGateway.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      await _syncFromUser(_authGateway.currentUser);
      _infoMessage = null;
    });
  }

  Future<bool> signOut() async {
    _errorMessage = null;
    _infoMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      await _authGateway.signOut();
      await _syncFromUser(null);
      return true;
    } catch (error) {
      _errorMessage = _mapError(error);
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _runAuthAction(() async {
      await _authGateway.signUp(
        email: email.trim(),
        password: password,
        displayName: displayName?.trim(),
      );
      await _syncFromUser(_authGateway.currentUser);
      _infoMessage = isAuthenticated
          ? 'Account created successfully.'
          : 'Account created. Check your email to continue.';
    });
  }

  void clearMessages() {
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    _errorMessage = null;
    _infoMessage = null;
    _isBusy = true;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = _mapError(error);
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _syncFromUser(AuthUserIdentity? user) async {
    final syncVersion = ++_syncVersion;
    try {
      final profile = user == null
          ? null
          : await _profileRepository.fetchByUserId(user.id);

      if (syncVersion != _syncVersion) {
        return;
      }

      _currentUser = user;
      _profile = profile;
      _errorMessage = null;
    } catch (error) {
      if (syncVersion != _syncVersion) {
        return;
      }

      _currentUser = user;
      _profile = null;
      _errorMessage = _mapError(error);
    }
    if (syncVersion == _syncVersion) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  String _mapError(Object error) {
    if (error is AuthGatewayException) {
      return error.message;
    }

    return error.toString();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
