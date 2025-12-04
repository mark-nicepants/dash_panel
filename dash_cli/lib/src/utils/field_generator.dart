import 'dart:math';

import 'package:dash_cli/src/generators/schema_parser.dart';
import 'package:dash_cli/src/utils/password_utils.dart';
import 'package:faker/faker.dart';

/// Generates fake/default values for schema fields.
///
/// This class extracts the field value generation logic to be shared
/// between db:seed (bulk generation) and db:create (interactive creation).
class FieldGenerator {
  FieldGenerator({Faker? faker, Random? random}) : _faker = faker ?? Faker(), _random = random ?? Random();

  final Faker _faker;
  final Random _random;

  /// Generate a fake value for a field based on its type and constraints.
  ///
  /// [field] - The schema field definition
  /// [modelName] - The model name (for context-aware generation)
  /// [hashPasswords] - Whether to hash password fields with bcrypt (default: true)
  ///
  /// Returns a generated value appropriate for the field, or null if the field
  /// should be skipped (e.g., auto-increment primary key).
  dynamic generateValue(SchemaField field, String modelName, {bool hashPasswords = true}) {
    // Skip primary keys (auto-increment)
    if (field.isPrimaryKey) return null;

    // Skip timestamp fields (let DB handle them)
    if (_isTimestampField(field.name)) return null;

    // Skip hasMany relations (handled separately)
    if (field.relation?.type == 'hasMany' || field.relation?.type == 'hasOne') {
      return null;
    }

    // Handle enum values
    if (field.enumValues != null && field.enumValues!.isNotEmpty) {
      return field.enumValues![_random.nextInt(field.enumValues!.length)];
    }

    // Handle default values (30% chance to use default if available)
    if (field.defaultValue != null && _random.nextDouble() < 0.3) {
      return field.defaultValue;
    }

    // Generate based on field type
    return _generateByType(field, modelName, hashPasswords: hashPasswords);
  }

  /// Generate a default value for interactive prompts.
  ///
  /// Similar to generateValue but always generates a value (no null returns
  /// for optional fields) and formats it for display.
  String generateDefaultForPrompt(SchemaField field, String modelName) {
    final value = _generateByType(field, modelName, hashPasswords: false);
    if (value == null) return '';

    if (value is bool) {
      return value ? 'true' : 'false';
    }
    return value.toString();
  }

  bool _isTimestampField(String name) {
    return name == 'createdAt' || name == 'updatedAt' || name == 'deletedAt';
  }

  dynamic _generateByType(SchemaField field, String modelName, {bool hashPasswords = true}) {
    final name = field.name.toLowerCase();
    final type = field.dartType;

    // String fields - use field name hints
    if (type == 'String') {
      return _generateStringValue(name, field, hashPasswords: hashPasswords);
    }

    // Integer fields
    if (type == 'int') {
      final min = field.min?.toInt() ?? 0;
      final max = field.max?.toInt() ?? 1000;
      return min + _random.nextInt(max - min + 1);
    }

    // Double fields
    if (type == 'double') {
      final min = field.min?.toDouble() ?? 0.0;
      final max = field.max?.toDouble() ?? 1000.0;
      return min + _random.nextDouble() * (max - min);
    }

    // Boolean fields
    if (type == 'bool') {
      return _generateBoolValue(name);
    }

    // DateTime fields
    if (type == 'DateTime') {
      return _generateDateTimeValue(name);
    }

    return null;
  }

  bool _generateBoolValue(String fieldName) {
    // Handle common boolean patterns
    if (fieldName.contains('active') || fieldName.contains('enabled') || fieldName.contains('published')) {
      return _random.nextDouble() < 0.8; // 80% true
    }
    if (fieldName.contains('deleted') || fieldName.contains('archived') || fieldName.contains('hidden')) {
      return _random.nextDouble() < 0.1; // 10% true
    }
    return _random.nextBool();
  }

  String _generateDateTimeValue(String fieldName) {
    final now = DateTime.now();
    if (fieldName.contains('birth') || fieldName.contains('dob')) {
      // Birth date: 18-80 years ago
      return now.subtract(Duration(days: 365 * (18 + _random.nextInt(62)))).toIso8601String();
    }
    // Default: within last year
    return now.subtract(Duration(days: _random.nextInt(365))).toIso8601String();
  }

  String _generateStringValue(String fieldName, SchemaField field, {bool hashPasswords = true}) {
    // Email fields
    if (fieldName.contains('email')) {
      return _faker.internet.email();
    }

    // Name fields
    if (fieldName == 'name' || fieldName == 'fullname' || fieldName == 'full_name') {
      return _faker.person.name();
    }
    if (fieldName == 'firstname' || fieldName == 'first_name') {
      return _faker.person.firstName();
    }
    if (fieldName == 'lastname' || fieldName == 'last_name') {
      return _faker.person.lastName();
    }

    // Username
    if (fieldName.contains('username') || fieldName.contains('user_name')) {
      return _faker.internet.userName();
    }

    // Password - generate and optionally hash
    if (fieldName.contains('password')) {
      final plainPassword = _generateSecurePassword();
      if (hashPasswords) {
        return PasswordUtils.hash(plainPassword);
      }
      return plainPassword;
    }

    // Title fields
    if (fieldName == 'title') {
      return _faker.lorem.sentence();
    }

    // Slug fields
    if (fieldName == 'slug') {
      return _faker.lorem.words(3).join('-').toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    }

    // Content/body/description
    if (fieldName == 'content' || fieldName == 'body' || fieldName == 'text') {
      return _faker.lorem.sentences(_random.nextInt(5) + 3).join(' ');
    }
    if (fieldName == 'description' || fieldName == 'summary' || fieldName == 'excerpt') {
      return _faker.lorem.sentence();
    }

    // URL fields
    if (fieldName.contains('url') || fieldName.contains('link') || fieldName.contains('website')) {
      return _faker.internet.httpsUrl();
    }

    // Avatar/image fields
    if (fieldName.contains('avatar') || fieldName.contains('image') || fieldName.contains('photo')) {
      return 'https://i.pravatar.cc/150?u=${_faker.internet.email()}';
    }

    // Phone fields
    if (fieldName.contains('phone') || fieldName.contains('mobile') || fieldName.contains('tel')) {
      return _faker.phoneNumber.us();
    }

    // Address fields
    if (fieldName.contains('address')) {
      return _faker.address.streetAddress();
    }
    if (fieldName == 'city') {
      return _faker.address.city();
    }
    if (fieldName == 'country') {
      return _faker.address.country();
    }
    if (fieldName.contains('zip') || fieldName.contains('postal')) {
      return _faker.address.zipCode();
    }

    // Company fields
    if (fieldName.contains('company') || fieldName.contains('organization')) {
      return _faker.company.name();
    }

    // Color fields
    if (fieldName.contains('color')) {
      return '#${_random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    }

    // IP address
    if (fieldName.contains('ip')) {
      return '${_random.nextInt(256)}.${_random.nextInt(256)}.${_random.nextInt(256)}.${_random.nextInt(256)}';
    }

    // Default: lorem words with length constraint
    final maxLen = field.max?.toInt() ?? 255;
    final minLen = field.min?.toInt() ?? 1;
    var result = _faker.lorem.words(_random.nextInt(3) + 1).join(' ');

    if (result.length > maxLen) {
      result = result.substring(0, maxLen);
    }
    if (result.length < minLen) {
      result = result.padRight(minLen, 'x');
    }

    return result;
  }

  /// Generate a secure random password.
  String _generateSecurePassword({int length = 16}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  /// Convert a boolean to SQLite integer (0 or 1).
  int boolToSqlite(bool value) => value ? 1 : 0;

  /// Parse user input into the appropriate type for a field.
  ///
  /// [input] - The user's input string
  /// [field] - The schema field definition
  /// [hashPasswords] - Whether to hash password fields
  ///
  /// Returns the parsed value in the correct type for database storage.
  dynamic parseInput(String input, SchemaField field, {bool hashPasswords = true}) {
    if (input.isEmpty) return null;

    final type = field.dartType;
    final name = field.name.toLowerCase();

    switch (type) {
      case 'int':
        return int.tryParse(input);
      case 'double':
        return double.tryParse(input);
      case 'bool':
        final lower = input.toLowerCase();
        if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 'y') {
          return 1; // SQLite stores booleans as integers
        }
        if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'n') {
          return 0;
        }
        return null;
      case 'DateTime':
        // Accept various date formats
        final parsed = DateTime.tryParse(input);
        return parsed?.toIso8601String();
      case 'String':
      default:
        // Hash password fields if they're not already hashed
        if (name.contains('password') && hashPasswords && !PasswordUtils.isBcryptHash(input)) {
          return PasswordUtils.hash(input);
        }
        return input;
    }
  }
}
