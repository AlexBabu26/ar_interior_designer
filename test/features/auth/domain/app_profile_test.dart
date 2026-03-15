import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/auth/domain/app_profile.dart';

void main() {
  group('AppProfile', () {
    test('parses a customer profile from json', () {
      final profile = AppProfile.fromJson({
        'id': 'user-123',
        'email': 'customer@example.com',
        'display_name': 'Customer',
        'role': 'customer',
        'created_at': '2026-03-15T10:00:00.000Z',
        'updated_at': '2026-03-15T11:00:00.000Z',
      });

      expect(profile.id, 'user-123');
      expect(profile.email, 'customer@example.com');
      expect(profile.displayName, 'Customer');
      expect(profile.role, AppProfileRole.customer);
      expect(profile.isAdmin, isFalse);
      expect(profile.createdAt, DateTime.parse('2026-03-15T10:00:00.000Z'));
      expect(profile.updatedAt, DateTime.parse('2026-03-15T11:00:00.000Z'));
    });

    test('serializes an admin profile to json', () {
      final profile = AppProfile(
        id: 'admin-1',
        email: 'admin@example.com',
        displayName: null,
        role: AppProfileRole.admin,
        createdAt: DateTime.parse('2026-03-15T12:00:00.000Z'),
        updatedAt: DateTime.parse('2026-03-15T13:00:00.000Z'),
      );

      expect(profile.toJson(), {
        'id': 'admin-1',
        'email': 'admin@example.com',
        'display_name': null,
        'role': 'admin',
        'created_at': '2026-03-15T12:00:00.000Z',
        'updated_at': '2026-03-15T13:00:00.000Z',
      });
      expect(profile.isAdmin, isTrue);
    });

    test('throws FormatException for invalid role strings', () {
      expect(
        () => AppProfile.fromJson({
          'id': 'user-456',
          'email': 'bad-role@example.com',
          'display_name': 'Bad Role',
          'role': 'owner',
          'created_at': '2026-03-15T14:00:00.000Z',
          'updated_at': '2026-03-15T15:00:00.000Z',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
