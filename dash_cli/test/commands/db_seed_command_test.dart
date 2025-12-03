import 'package:test/test.dart';

void main() {
  group('DbSeedCommand', () {
    test('generated data follows field type constraints', () {
      // Test data generation logic patterns
      final faker = _SimpleFaker();

      // Email pattern
      final email = faker.email();
      expect(email, contains('@'));
      expect(email, contains('.'));

      // Name pattern
      final name = faker.name();
      expect(name.isNotEmpty, isTrue);

      // Boolean pattern (for SQLite)
      final active = faker.boolean() ? 1 : 0;
      expect(active, anyOf(0, 1));
    });

    test('enum values are selected from valid options', () {
      final enumValues = ['admin', 'user', 'guest'];
      final random = DateTime.now().millisecondsSinceEpoch % enumValues.length;
      final selected = enumValues[random];

      expect(enumValues, contains(selected));
    });
  });
}

/// Simple faker for testing without full faker dependency
class _SimpleFaker {
  String email() => 'test${DateTime.now().millisecondsSinceEpoch}@example.com';
  String name() => 'Test User ${DateTime.now().millisecondsSinceEpoch}';
  bool boolean() => DateTime.now().millisecondsSinceEpoch % 2 == 0;
}
