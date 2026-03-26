import 'package:flutter_test/flutter_test.dart';
import 'package:orientpro_mobile/models/user.dart';

void main() {
  group('User Model', () {
    test('fromJson - tam veri ile olusturma', () {
      final json = {
        'id': 'test-uuid-123',
        'email': 'test@orientpro.com',
        'full_name': 'Test Kullanici',
        'role': 'admin',
        'department': 'teknik',
        'is_active': true,
        'organization_id': 'org-uuid-456',
      };

      final user = User.fromJson(json);

      expect(user.id, 'test-uuid-123');
      expect(user.email, 'test@orientpro.com');
      expect(user.fullName, 'Test Kullanici');
      expect(user.role, 'admin');
      expect(user.department, 'teknik');
      expect(user.isActive, true);
      expect(user.organizationId, 'org-uuid-456');
    });

    test('fromJson - minimum zorunlu alanlar', () {
      final json = {
        'id': 'test-uuid',
        'email': 'test@test.com',
        'full_name': 'Test',
        'role': 'personel',
        'department': 'teknik',
        'is_active': true,
        'organization_id': 'org-1',
      };

      final user = User.fromJson(json);

      expect(user.id, 'test-uuid');
      expect(user.email, 'test@test.com');
      expect(user.role, 'personel');
    });

    test('roleText - Turkce karsilik', () {
      final admin = User.fromJson({
        'id': '1', 'email': 'a@b.com', 'full_name': 'Admin User',
        'role': 'admin', 'department': 'it', 'is_active': true,
        'organization_id': 'org-1',
      });
      expect(admin.roleText, isNotEmpty);

      final teknik = User.fromJson({
        'id': '2', 'email': 'b@b.com', 'full_name': 'Teknik',
        'role': 'teknik_mudur', 'department': 'teknik', 'is_active': true,
        'organization_id': 'org-1',
      });
      expect(teknik.roleText, isNotEmpty);
    });
  });
}
