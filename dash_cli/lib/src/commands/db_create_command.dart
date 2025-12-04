import 'dart:io';

import 'package:dash/dash.dart';
import 'package:dash_cli/src/commands/base_command.dart';
import 'package:dash_cli/src/commands/completion_configuration.dart';
import 'package:dash_cli/src/commands/dcli_argument.dart';
import 'package:dash_cli/src/generators/schema_parser.dart';
import 'package:dash_cli/src/utils/console_utils.dart';
import 'package:dash_cli/src/utils/field_generator.dart';

/// Interactively create a single model record.
///
/// Usage:
///   dcli db:create [model] [options]
///
/// Examples:
///   dcli db:create User
///   dcli db:create Post --non-interactive
///
/// Options:
///   -d, --database         Path to database file
///   -s, --schemas          Path to schema YAML files
///   --non-interactive      Use generated values without prompting
///   -l, --list             List available models
class DbCreateCommand extends BaseCommand with DatabaseCommandMixin, SchemaCommandMixin {
  DbCreateCommand() {
    DcliArgument.addToParser(argParser, _arguments);
  }

  /// Unified argument definitions.
  static final _arguments = [
    // Positional
    DcliArgument.positional(
      name: 'model',
      help: 'The model to create a record for',
      completionType: CompletionType.model,
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
      help: 'Path to schema directory',
      completionType: CompletionType.directory,
    ),
    // Flags
    DcliArgument.flag(name: 'non-interactive', abbr: 'n', help: 'Use generated values without prompting'),
    DcliArgument.flag(name: 'list', abbr: 'l', help: 'List available models'),
    DcliArgument.flag(name: 'verbose', abbr: 'v', help: 'Show detailed output'),
  ];

  @override
  final String name = 'db:create';

  @override
  final String description = 'Interactively create a single model record';

  @override
  final List<String> aliases = ['create'];

  @override
  final String invocation = 'dcli db:create <model>';

  final FieldGenerator _fieldGenerator = FieldGenerator();

  @override
  Future<int> run() async {
    final listModels = argResults!['list'] as bool;
    final nonInteractive = argResults!['non-interactive'] as bool;
    final verbose = argResults!['verbose'] as bool;
    final rest = argResults!.rest;

    ConsoleUtils.header('✨ Create Record');

    // Load schemas
    Map<String, ParsedSchema> schemas;
    try {
      schemas = loadSchemas(schemasPath: effectiveSchemasPath);
    } catch (e) {
      ConsoleUtils.error('Failed to load schemas: $e');
      return 1;
    }

    if (schemas.isEmpty) {
      ConsoleUtils.error('No schema files found in $effectiveSchemasPath');
      return 1;
    }

    // List models mode
    if (listModels) {
      _printAvailableModels(schemas);
      return 0;
    }

    // Validate model argument
    if (rest.isEmpty) {
      ConsoleUtils.error('Please specify a model to create');
      print('');
      _printAvailableModels(schemas);
      return 1;
    }

    final modelName = rest[0].toLowerCase();
    final schema = schemas[modelName];

    if (schema == null) {
      ConsoleUtils.error('Model not found: ${rest[0]}');
      print('');
      _printAvailableModels(schemas);
      return 1;
    }

    ConsoleUtils.info('Model: ${schema.modelName}');
    ConsoleUtils.info('Table: ${schema.config.table}');
    print('');

    // Connect to database
    try {
      final db = await getDatabase(databasePath: effectiveDatabasePath);

      // Verify table exists
      if (!await db.tableExists(schema.config.table)) {
        ConsoleUtils.error('Table "${schema.config.table}" not found in database');
        await db.close();
        return 1;
      }

      // Load foreign key values for relationships
      final foreignKeyValues = await _loadForeignKeyValues(db, schema);

      // Collect field values
      Map<String, dynamic> data;
      if (nonInteractive) {
        data = _generateAllValues(schema, foreignKeyValues);
      } else {
        data = await _promptForValues(schema, foreignKeyValues, verbose);
        if (data.isEmpty) {
          ConsoleUtils.info('Operation cancelled');
          await db.close();
          return 0;
        }
      }

      if (data.isEmpty) {
        ConsoleUtils.error('No data to insert');
        await db.close();
        return 1;
      }

      // Insert the record
      if (verbose) {
        print('');
        ConsoleUtils.info('Inserting data:');
        for (final entry in data.entries) {
          final displayValue = entry.key.toLowerCase().contains('password') ? '********' : entry.value.toString();
          print('  ${entry.key}: $displayValue');
        }
      }

      final insertedId = await db.insert(schema.config.table, data);
      await db.close();

      print('');
      ConsoleUtils.line();
      ConsoleUtils.success('Created ${schema.modelName} #$insertedId');
      print('');

      // Show the created record
      if (!nonInteractive || verbose) {
        _printCreatedRecord(data, insertedId, schema);
      }

      return 0;
    } catch (e) {
      ConsoleUtils.error('Database error: $e');
      return 1;
    }
  }

  void _printAvailableModels(Map<String, ParsedSchema> schemas) {
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
    print('Usage: dcli db:create <model>');
  }

  Future<Map<String, List<dynamic>>> _loadForeignKeyValues(DatabaseConnector db, ParsedSchema schema) async {
    final foreignKeyValues = <String, List<dynamic>>{};

    for (final field in schema.fields) {
      if (field.relation?.type == 'belongsTo') {
        final relatedTable = toSnakeCase(field.relation!.model);
        // Try plural table name
        final pluralTable = '${relatedTable}s';

        try {
          final values = await db.getColumnValues(pluralTable, 'id');
          if (values.isNotEmpty) {
            foreignKeyValues[field.columnName] = values;
          }
        } catch (_) {
          // Table might not exist
        }
      }
    }

    return foreignKeyValues;
  }

  Map<String, dynamic> _generateAllValues(ParsedSchema schema, Map<String, List<dynamic>> foreignKeyValues) {
    final data = <String, dynamic>{};

    for (final field in schema.fields) {
      // Skip primary keys
      if (field.isPrimaryKey) continue;

      // Skip timestamp fields
      if (_isTimestampField(field.name)) continue;

      // Handle foreign keys
      if (field.relation?.type == 'belongsTo') {
        final fkValues = foreignKeyValues[field.columnName];
        if (fkValues != null && fkValues.isNotEmpty) {
          data[field.columnName] = fkValues[0]; // Use first available
        }
        continue;
      }

      // Skip hasMany relations
      if (field.relation?.type == 'hasMany' || field.relation?.type == 'hasOne') {
        continue;
      }

      // Generate value
      final value = _fieldGenerator.generateValue(field, schema.modelName, hashPasswords: true);
      if (value != null) {
        // Convert booleans to SQLite integer format
        if (field.dartType == 'bool' && value is bool) {
          data[field.columnName] = value ? 1 : 0;
        } else {
          data[field.columnName] = value;
        }
      }
    }

    return data;
  }

  Future<Map<String, dynamic>> _promptForValues(
    ParsedSchema schema,
    Map<String, List<dynamic>> foreignKeyValues,
    bool verbose,
  ) async {
    final data = <String, dynamic>{};

    print('${ConsoleUtils.gray}Enter values for each field (press Enter for generated default):${ConsoleUtils.reset}');
    print('${ConsoleUtils.gray}Type "cancel" to abort.${ConsoleUtils.reset}');
    print('');

    for (final field in schema.fields) {
      // Skip primary keys
      if (field.isPrimaryKey) continue;

      // Skip timestamp fields
      if (_isTimestampField(field.name)) continue;

      // Skip hasMany relations
      if (field.relation?.type == 'hasMany' || field.relation?.type == 'hasOne') {
        continue;
      }

      // Handle foreign keys
      if (field.relation?.type == 'belongsTo') {
        final fkValues = foreignKeyValues[field.columnName];
        final value = await _promptForeignKey(field, fkValues);
        if (value == 'cancel') return {};
        if (value != null) {
          data[field.columnName] = value;
        }
        continue;
      }

      // Prompt for regular fields
      final value = await _promptField(field, schema.modelName);
      if (value == 'cancel') return {};
      if (value != null) {
        data[field.columnName] = value;
      } else if (field.isRequired && field.defaultValue == null) {
        // Required field with no value - generate one
        final generated = _fieldGenerator.generateValue(field, schema.modelName, hashPasswords: true);
        if (generated != null) {
          if (field.dartType == 'bool' && generated is bool) {
            data[field.columnName] = generated ? 1 : 0;
          } else {
            data[field.columnName] = generated;
          }
        }
      }
    }

    return data;
  }

  Future<dynamic> _promptField(SchemaField field, String modelName) async {
    final isPassword = field.name.toLowerCase().contains('password');
    final defaultValue = _fieldGenerator.generateDefaultForPrompt(field, modelName);

    // Build prompt string
    final buffer = StringBuffer();
    buffer.write('${ConsoleUtils.cyan}${field.name}${ConsoleUtils.reset}');
    buffer.write(' ${ConsoleUtils.gray}(${field.dartType}');
    if (field.isRequired) buffer.write(', required');
    if (field.enumValues != null) {
      buffer.write(', options: ${field.enumValues!.join('|')}');
    }
    buffer.write(')${ConsoleUtils.reset}');

    if (defaultValue.isNotEmpty && !isPassword) {
      buffer.write(' [${ConsoleUtils.gray}$defaultValue${ConsoleUtils.reset}]');
    }
    buffer.write(': ');

    stdout.write(buffer.toString());
    final input = stdin.readLineSync() ?? '';

    if (input.toLowerCase() == 'cancel') {
      return 'cancel';
    }

    if (input.isEmpty) {
      // Use generated value
      final generated = _fieldGenerator.generateValue(field, modelName, hashPasswords: true);
      if (generated is bool) {
        return generated ? 1 : 0;
      }
      return generated;
    }

    // Parse the input
    return _fieldGenerator.parseInput(input, field, hashPasswords: true);
  }

  Future<dynamic> _promptForeignKey(SchemaField field, List<dynamic>? availableValues) async {
    final buffer = StringBuffer();
    buffer.write('${ConsoleUtils.cyan}${field.columnName}${ConsoleUtils.reset}');
    buffer.write(' ${ConsoleUtils.gray}(foreign key to ${field.relation!.model})${ConsoleUtils.reset}');

    if (availableValues != null && availableValues.isNotEmpty) {
      buffer.write(' ${ConsoleUtils.gray}[available: ${availableValues.take(5).join(', ')}');
      if (availableValues.length > 5) {
        buffer.write('...');
      }
      buffer.write(']${ConsoleUtils.reset}');
    }
    buffer.write(': ');

    stdout.write(buffer.toString());
    final input = stdin.readLineSync() ?? '';

    if (input.toLowerCase() == 'cancel') {
      return 'cancel';
    }

    if (input.isEmpty) {
      // Use first available value or null
      return availableValues?.firstOrNull;
    }

    return int.tryParse(input) ?? input;
  }

  bool _isTimestampField(String name) {
    return name == 'createdAt' || name == 'updatedAt' || name == 'deletedAt';
  }

  void _printCreatedRecord(Map<String, dynamic> data, int id, ParsedSchema schema) {
    print('');
    print('${ConsoleUtils.bold}Created Record:${ConsoleUtils.reset}');
    print('  id: $id');
    for (final entry in data.entries) {
      final displayValue = entry.key.toLowerCase().contains('password') ? '********' : entry.value.toString();
      // Truncate long values
      final truncated = displayValue.length > 50 ? '${displayValue.substring(0, 47)}...' : displayValue;
      print('  ${entry.key}: $truncated');
    }
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
