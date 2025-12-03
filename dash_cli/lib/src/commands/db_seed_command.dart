import 'dart:io';
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:dash_cli/src/generators/schema_parser.dart';
import 'package:dash_cli/src/utils/console_utils.dart';
import 'package:faker/faker.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

/// Seed the database with fake data.
///
/// Usage:
///   dash db:seed model [count] [options]
///
/// Examples:
///   dash db:seed User 100
///   dash db:seed Post 50 --database storage/app.db
///
/// Options:
///   -d, --database    Path to SQLite database file
///   -s, --schemas     Path to schema YAML files
class DbSeedCommand extends Command<int> {
  DbSeedCommand() {
    argParser
      ..addOption('database', abbr: 'd', help: 'Path to SQLite database file', defaultsTo: 'storage/app.db')
      ..addOption(
        'schemas',
        abbr: 's',
        help: 'Path to directory containing schema YAML files',
        defaultsTo: 'schemas/models',
      )
      ..addFlag('verbose', abbr: 'v', help: 'Show detailed output', defaultsTo: false)
      ..addFlag('list', abbr: 'l', help: 'List available models to seed', defaultsTo: false);
  }
  @override
  final String name = 'db:seed';

  @override
  final String description = 'Seed the database with fake data based on model schema';

  @override
  final List<String> aliases = ['seed'];

  @override
  final String invocation = 'dash db:seed <model> [count]';

  final _faker = Faker();
  final _random = Random();

  @override
  Future<int> run() async {
    final databasePath = argResults!['database'] as String;
    final schemasPath = argResults!['schemas'] as String;
    final verbose = argResults!['verbose'] as bool;
    final listModels = argResults!['list'] as bool;

    // Parse positional arguments
    final rest = argResults!.rest;

    ConsoleUtils.header('🌱 Database Seeder');

    // Check schemas directory exists
    if (!Directory(schemasPath).existsSync()) {
      ConsoleUtils.error('Schemas directory not found: $schemasPath');
      return 1;
    }

    // Find all schema files
    final schemaFiles = Directory(
      schemasPath,
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml')).toList();

    if (schemaFiles.isEmpty) {
      ConsoleUtils.error('No schema files found in $schemasPath');
      return 1;
    }

    // Parse all schemas
    final parser = SchemaParser();
    final schemas = <String, ParsedSchema>{};

    for (final file in schemaFiles) {
      try {
        final schema = parser.parseFile(file.path);
        schemas[schema.modelName.toLowerCase()] = schema;
      } catch (e) {
        if (verbose) {
          ConsoleUtils.warning('Failed to parse ${path.basename(file.path)}: $e');
        }
      }
    }

    // List models mode
    if (listModels) {
      ConsoleUtils.info('Available models:');
      print('');
      for (final schema in schemas.values) {
        final fields = schema.fields.where((f) => !f.isPrimaryKey).length;
        print(
          '  ${ConsoleUtils.cyan}${schema.modelName}${ConsoleUtils.reset} '
          '${ConsoleUtils.gray}($fields fields, table: ${schema.config.table})${ConsoleUtils.reset}',
        );
      }
      print('');
      print('Usage: dash db:seed <model> [count]');
      return 0;
    }

    // Validate arguments
    if (rest.isEmpty) {
      ConsoleUtils.error('Please specify a model to seed');
      print('');
      print('Usage: dash db:seed <model> [count]');
      print('');
      print('Available models:');
      for (final name in schemas.keys) {
        print('  • ${schemas[name]!.modelName}');
      }
      return 1;
    }

    final modelName = rest[0].toLowerCase();
    final count = rest.length > 1 ? int.tryParse(rest[1]) ?? 10 : 10;

    // Find schema
    final schema = schemas[modelName];
    if (schema == null) {
      ConsoleUtils.error('Model not found: ${rest[0]}');
      print('');
      print('Available models:');
      for (final name in schemas.keys) {
        print('  • ${schemas[name]!.modelName}');
      }
      return 1;
    }

    // Check database exists
    if (!File(databasePath).existsSync()) {
      ConsoleUtils.error('Database not found: $databasePath');
      print('');
      print('Make sure the database file exists. Run your Dash server first to create it.');
      return 1;
    }

    ConsoleUtils.info('Model: ${schema.modelName}');
    ConsoleUtils.info('Table: ${schema.config.table}');
    ConsoleUtils.info('Count: $count');
    print('');

    try {
      final db = sqlite3.open(databasePath);

      // Verify table exists
      final tables = db.select("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [schema.config.table]);

      if (tables.isEmpty) {
        ConsoleUtils.error('Table "${schema.config.table}" not found in database');
        db.close();
        return 1;
      }

      // Get existing foreign key values for belongsTo relationships
      final foreignKeyValues = <String, List<int>>{};
      for (final field in schema.fields) {
        if (field.relation?.type == 'belongsTo') {
          final relatedTable = _toSnakeCase(field.relation!.model);
          // Try plural table name
          final pluralTable = '${relatedTable}s';

          try {
            final rows = db.select('SELECT id FROM "$pluralTable" LIMIT 1000');
            if (rows.isNotEmpty) {
              foreignKeyValues[field.columnName] = rows.map((r) => r['id'] as int).toList();
            }
          } catch (_) {
            // Table might not exist or have different structure
          }
        }
      }

      // Generate and insert records
      var inserted = 0;
      final startTime = DateTime.now();

      for (var i = 0; i < count; i++) {
        final data = _generateFakeData(schema, foreignKeyValues);

        if (data.isEmpty) continue;

        final columns = data.keys.toList();
        final values = data.values.toList();
        final placeholders = List.filled(columns.length, '?').join(', ');

        try {
          db.execute('INSERT INTO "${schema.config.table}" (${columns.join(', ')}) VALUES ($placeholders)', values);
          inserted++;

          if (verbose) {
            ConsoleUtils.success('Created ${schema.modelName} #${db.lastInsertRowId}');
          } else {
            ConsoleUtils.progressBar(i + 1, count, prefix: 'Seeding');
          }
        } catch (e) {
          if (verbose) {
            ConsoleUtils.error('Failed to insert record: $e');
          }
        }
      }

      final duration = DateTime.now().difference(startTime);
      db.close();

      print('');
      ConsoleUtils.line();
      ConsoleUtils.success(
        'Inserted $inserted ${schema.modelName} record(s) in ${ConsoleUtils.formatDuration(duration)}',
      );
      print('');

      return 0;
    } catch (e) {
      ConsoleUtils.error('Database error: $e');
      return 1;
    }
  }

  Map<String, dynamic> _generateFakeData(ParsedSchema schema, Map<String, List<int>> foreignKeyValues) {
    final data = <String, dynamic>{};

    for (final field in schema.fields) {
      // Skip primary keys (auto-increment)
      if (field.isPrimaryKey) continue;

      // Skip timestamp fields (let DB handle them)
      if (field.name == 'createdAt' || field.name == 'updatedAt' || field.name == 'deletedAt') {
        continue;
      }

      // Handle foreign keys
      if (field.relation?.type == 'belongsTo') {
        final fkValues = foreignKeyValues[field.columnName];
        if (fkValues != null && fkValues.isNotEmpty) {
          data[field.columnName] = fkValues[_random.nextInt(fkValues.length)];
        } else if (field.isRequired) {
          // Skip required FK if no values available
          return {};
        }
        continue;
      }

      // Skip hasMany relations (handled separately)
      if (field.relation?.type == 'hasMany' || field.relation?.type == 'hasOne') {
        continue;
      }

      // Handle nullable fields - sometimes generate null
      if (field.isNullable && _random.nextDouble() < 0.1) {
        continue; // Skip (will be null)
      }

      // Generate value based on type and constraints
      final value = _generateFieldValue(field, schema.modelName);
      if (value != null) {
        data[field.columnName] = value;
      }
    }

    return data;
  }

  dynamic _generateFieldValue(SchemaField field, String modelName) {
    // Handle enum values
    if (field.enumValues != null && field.enumValues!.isNotEmpty) {
      return field.enumValues![_random.nextInt(field.enumValues!.length)];
    }

    // Handle default values
    if (field.defaultValue != null && _random.nextDouble() < 0.3) {
      return field.defaultValue;
    }

    // Generate based on field name hints and type
    final name = field.name.toLowerCase();
    final type = field.dartType;

    // String fields - use field name hints
    if (type == 'String') {
      return _generateStringValue(name, field);
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
      // Handle common boolean patterns
      if (name.contains('active') || name.contains('enabled') || name.contains('published')) {
        return _random.nextDouble() < 0.8 ? 1 : 0; // 80% true
      }
      if (name.contains('deleted') || name.contains('archived') || name.contains('hidden')) {
        return _random.nextDouble() < 0.1 ? 1 : 0; // 10% true
      }
      return _random.nextBool() ? 1 : 0;
    }

    // DateTime fields
    if (type == 'DateTime') {
      final now = DateTime.now();
      if (name.contains('birth') || name.contains('dob')) {
        // Birth date: 18-80 years ago
        return now.subtract(Duration(days: 365 * (18 + _random.nextInt(62)))).toIso8601String();
      }
      // Default: within last year
      return now.subtract(Duration(days: _random.nextInt(365))).toIso8601String();
    }

    return null;
  }

  String _generateStringValue(String fieldName, SchemaField field) {
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

    // Password (hashed placeholder - should be replaced with actual hash)
    if (fieldName.contains('password')) {
      // Return a bcrypt-like hash placeholder
      return '\$2b\$10\$${_faker.lorem.word()}${_faker.lorem.word()}${_faker.lorem.word()}';
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

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }
}
