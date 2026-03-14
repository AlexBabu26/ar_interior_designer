import '../entities/models.dart';

abstract class AuthRepository {
  Future<User?> register(String email, String password);
  Future<User?> login(String email, String password);
  Future<User?> getUserById(String id);
}
