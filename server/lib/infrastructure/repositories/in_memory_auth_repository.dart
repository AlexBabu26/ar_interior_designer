import 'package:uuid/uuid.dart';

import '../../../domain/entities/models.dart';
import '../../../domain/repositories/auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  final Map<String, User> _users = {};

  @override
  Future<User?> register(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_users.values.any((user) => user.email == email)) {
      return null; // User already exists
    }
    final user = User(id: const Uuid().v4(), email: email, password: password);
    _users[user.id] = user;
    return user;
  }

  @override
  Future<User?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _users.values.firstWhere(
      (user) => user.email == email && user.password == password,
      orElse: () => throw Exception('Invalid credentials'),
    );
  }

  @override
  Future<User?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _users[id];
  }
}
