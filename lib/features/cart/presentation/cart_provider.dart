import 'dart:async';

import 'package:flutter/material.dart';

import '../../auth/application/auth_provider.dart';
import '../../catalog/domain/product.dart';
import '../data/cart_repository.dart';
import '../domain/cart_item.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = <String, CartItem>{};
  CartRepository? _repository;
  AuthProvider? _authProvider;
  String? _currentUserId;
  bool _isBusy = false;
  String? _errorMessage;

  List<CartItem> get items => _items.values.toList();

  int get itemCount =>
      _items.values.fold<int>(0, (total, item) => total + item.quantity);

  bool get isBusy => _isBusy;

  bool get isSignedIn => _currentUserId != null;

  String? get errorMessage => _errorMessage;

  double get totalAmount {
    return _items.values.fold<double>(
      0,
      (total, item) => total + (item.product.price * item.quantity),
    );
  }

  void configure({
    required CartRepository repository,
    required AuthProvider authProvider,
  }) {
    _repository = repository;

    if (!identical(_authProvider, authProvider)) {
      _authProvider?.removeListener(_handleAuthChanged);
      _authProvider = authProvider;
      _authProvider?.addListener(_handleAuthChanged);
    }

    unawaited(_syncForAuthState());
  }

  Future<void> addItem(Product product) async {
    _errorMessage = null;
    if (!isSignedIn || _repository == null) {
      _addLocalItem(product);
      notifyListeners();
      return;
    }

    await _runRemoteMutation(() async {
      await _repository!.addItem(product);
      await _reloadRemoteItems();
    });
  }

  Future<void> clear() async {
    _errorMessage = null;
    if (!isSignedIn || _repository == null) {
      _items.clear();
      notifyListeners();
      return;
    }

    await _runRemoteMutation(() async {
      await _repository!.clear();
      await _reloadRemoteItems();
    });
  }

  Future<void> removeItem(String productId) async {
    _errorMessage = null;
    if (!isSignedIn || _repository == null) {
      _items.remove(productId);
      notifyListeners();
      return;
    }

    await _runRemoteMutation(() async {
      await _repository!.removeItem(productId);
      await _reloadRemoteItems();
    });
  }

  Future<void> removeSingleItem(String productId) async {
    _errorMessage = null;
    if (!isSignedIn || _repository == null) {
      final existingItem = _items[productId];
      if (existingItem == null) {
        return;
      }
      if (existingItem.quantity <= 1) {
        _items.remove(productId);
      } else {
        _items[productId] = existingItem.copyWith(
          quantity: existingItem.quantity - 1,
        );
      }
      notifyListeners();
      return;
    }

    await _runRemoteMutation(() async {
      await _repository!.removeSingleItem(productId);
      await _reloadRemoteItems();
    });
  }

  Future<void> refresh() async {
    if (!isSignedIn || _repository == null) {
      notifyListeners();
      return;
    }
    await _reloadRemoteItems();
  }

  Future<void> _runRemoteMutation(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _handleAuthChanged() async {
    await _syncForAuthState();
  }

  Future<void> _syncForAuthState() async {
    final nextUserId = _authProvider?.currentUser?.id;
    if (nextUserId == _currentUserId && (nextUserId == null || _items.isNotEmpty)) {
      return;
    }

    if (nextUserId == null) {
      _currentUserId = null;
      _items.clear();
      notifyListeners();
      return;
    }

    final guestItems = items;
    _currentUserId = nextUserId;

    if (_repository != null && guestItems.isNotEmpty) {
      for (final item in guestItems) {
        await _repository!.addItem(item.product, quantity: item.quantity);
      }
    }

    await _reloadRemoteItems();
  }

  Future<void> _reloadRemoteItems() async {
    if (_repository == null || !isSignedIn) {
      return;
    }

    final loadedItems = await _repository!.loadItems();
    _items
      ..clear()
      ..addEntries(
        loadedItems.map(
          (item) => MapEntry<String, CartItem>(item.product.id, item),
        ),
      );
    notifyListeners();
  }

  void _addLocalItem(Product product) {
    final existing = _items[product.id];
    if (existing == null) {
      _items[product.id] = CartItem(product: product);
      return;
    }

    _items[product.id] = existing.copyWith(quantity: existing.quantity + 1);
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
