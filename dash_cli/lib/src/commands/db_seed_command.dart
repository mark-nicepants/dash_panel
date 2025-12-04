import 'dart:io';
import 'dart:math';

import 'package:dash/dash.dart';
import 'package:dash_cli/src/commands/base_command.dart';
import 'package:dash_cli/src/commands/completion_configuration.dart';
import 'package:dash_cli/src/commands/dcli_argument.dart';
import 'package:dash_cli/src/generators/schema_parser.dart';
import 'package:dash_cli/src/utils/console_utils.dart';
import 'package:dash_cli/src/utils/field_generator.dart';
import 'package:path/path.dart' as path;

/// Seed the database with fake data.
///
/// Usage:
///   dcli db:seed model [count] [options]
///
/// Examples:
///   dcli db:seed User 100
///   dcli db:seed Post 50 --database storage/app.db
///
/// Options:
///   -d, --database    Path to database file
///   -s, --schemas     Path to schema YAML files
class DbSeedCommand extends BaseCommand with DatabaseCommandMixin {
  DbSeedCommand() {
    DcliArgument.addToParser(argParser, _arguments);
  }

  /// Unified argument definitions for both argParser and completion.
  static final _arguments = [
    // Positional arguments
    DcliArgument.positional(
      name: 'model',
      help: 'Model name to seed (e.g., User, Post)',
      completionType: CompletionType.model,
    ),
    DcliArgument.positional(
      name: 'count',
      help: 'Number of records to create (default: 10)',
      completionType: CompletionType.number,
    ),
    // Options
    DcliArgument.option(
      name: 'database',
      abbr: 'd',
      help: 'Path to database file',
      completionType: CompletionType.file,
      filePattern: '*.db',
    ),
    DcliArgument.option(
      name: 'schemas',
      abbr: 's',
      help: 'Path to directory containing schema YAML files',
      defaultsTo: 'schemas/models',
      completionType: CompletionType.directory,
    ),
    // Flags
    DcliArgument.flag(name: 'verbose', abbr: 'v', help: 'Show detailed output'),
    DcliArgument.flag(name: 'list', abbr: 'l', help: 'List available models to seed'),
  ];

  @override
  final String name = 'db:seed';

  @override
  final String description = 'Seed the database with fake data based on model schema';

  @override
  final List<String> aliases = ['seed'];

  @override
  final String invocation = 'dcli db:seed <model> [count]';

  final _fieldGenerator = FieldGenerator();
  final _random = Random();

  @override
  Future<int> run() async {
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
      print('Usage: dcli db:seed <model> [count]');
      return 0;
    }

    // Validate arguments
    if (rest.isEmpty) {
      ConsoleUtils.error('Please specify a model to seed');
      print('');
      print('Usage: dcli db:seed <model> [count]');
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
    if (!File(effectiveDatabasePath).existsSync()) {
      ConsoleUtils.error('Database not found: $effectiveDatabasePath');
      print('');
      print('Make sure the database file exists. Run your Dash server first to create it.');
      return 1;
    }

    ConsoleUtils.info('Model: ${schema.modelName}');
    ConsoleUtils.info('Table: ${schema.config.table}');
    ConsoleUtils.info('Database: $effectiveDatabasePath (${config.databaseDriver})');
    ConsoleUtils.info('Count: $count');
    print('');

    try {
      final db = await getDatabase(databasePath: effectiveDatabasePath);

      // Verify table exists
      if (!await db.tableExists(schema.config.table)) {
        ConsoleUtils.error('Table "${schema.config.table}" not found in database');
        await db.close();
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
            final rows = await db.query('SELECT id FROM "$pluralTable" LIMIT 1000');
            if (rows.isNotEmpty) {
              foreignKeyValues[field.columnName] = rows.map((r) => r['id'] as int).toList();
            }
          } catch (_) {
            // Table might not exist or have different structure
          }
        }
      }

      // Disable foreign key checks during bulk insert
      await db.disableForeignKeys();

      // Generate and insert records
      var inserted = 0;
      final startTime = DateTime.now();

      for (var i = 0; i < count; i++) {
        final data = _generateFakeData(schema, foreignKeyValues);

        if (data.isEmpty) continue;

        try {
          final lastId = await db.insert(schema.config.table, data);
          inserted++;

          if (verbose) {
            ConsoleUtils.success('Created ${schema.modelName} #$lastId');
          } else {
            ConsoleUtils.progressBar(i + 1, count, prefix: 'Seeding');
          }
        } catch (e) {
          if (verbose) {
            ConsoleUtils.error('Failed to insert record: $e');
          }
        }
      }

      // Re-enable foreign key checks
      await db.enableForeignKeys();

      final duration = DateTime.now().difference(startTime);
      await db.close();

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

      // Generate value using FieldGenerator
      final value = _fieldGenerator.generateValue(field, schema.modelName, hashPasswords: true);
      if (value != null) {
        // Convert booleans to SQLite integers
        if (value is bool) {
          data[field.columnName] = value ? 1 : 0;
        } else {
          data[field.columnName] = value;
        }
      }
    }

    return data;
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  @override
  CompletionConfiguration getCompletionConfig() {
    return DcliArgument.toCompletionConfig(
      name: name,
      description: description,
      arguments: _arguments,
      aliases: aliases,
    );
  }
}
