import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dash_cli/src/utils/console_utils.dart';
import 'package:sqlite3/sqlite3.dart';

/// Display database table schemas.
///
/// Usage:
///   dash db:schema [options]
///
/// Options:
///   -d, --database    Path to SQLite database file
///   -t, --table       Show only specific table
class DbSchemaCommand extends Command<int> {
  DbSchemaCommand() {
    argParser
      ..addOption('database', abbr: 'd', help: 'Path to SQLite database file', defaultsTo: 'storage/app.db')
      ..addOption('table', abbr: 't', help: 'Show schema for specific table only')
      ..addFlag('compact', abbr: 'c', help: 'Show compact output without column details', defaultsTo: false);
  }
  @override
  final String name = 'db:schema';

  @override
  final String description = 'Display database table schemas';

  @override
  final List<String> aliases = ['schema'];

  @override
  Future<int> run() async {
    final databasePath = argResults!['database'] as String;
    final specificTable = argResults!['table'] as String?;
    final compact = argResults!['compact'] as bool;

    ConsoleUtils.header('📊 Database Schema');

    // Check if database exists
    if (!File(databasePath).existsSync()) {
      ConsoleUtils.error('Database not found: $databasePath');
      print('');
      print('Make sure the database file exists. Run your Dash server first to create it.');
      return 1;
    }

    try {
      final db = sqlite3.open(databasePath);

      // Get list of tables
      final tables = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
      );

      if (tables.isEmpty) {
        ConsoleUtils.warning('No tables found in database');
        db.close();
        return 0;
      }

      ConsoleUtils.info('Database: $databasePath');
      ConsoleUtils.info('Tables: ${tables.length}');
      print('');

      for (final tableRow in tables) {
        final tableName = tableRow['name'] as String;

        // Filter by specific table if provided
        if (specificTable != null && tableName != specificTable) {
          continue;
        }

        // Get row count
        final countResult = db.select('SELECT COUNT(*) as count FROM "$tableName"');
        final rowCount = countResult.first['count'] as int;

        // Get table info (columns)
        final columns = db.select('PRAGMA table_info("$tableName")');

        // Print table header
        print(
          '${ConsoleUtils.bold}${ConsoleUtils.cyan}$tableName${ConsoleUtils.reset} '
          '${ConsoleUtils.gray}($rowCount rows)${ConsoleUtils.reset}',
        );

        if (!compact) {
          // Print column details
          final widths = [25, 15, 8, 10, 15];

          print('${ConsoleUtils.gray}${'─' * 75}${ConsoleUtils.reset}');
          ConsoleUtils.tableRow(['Column', 'Type', 'Null', 'Primary', 'Default'], widths);
          print('${ConsoleUtils.gray}${'─' * 75}${ConsoleUtils.reset}');

          for (final col in columns) {
            final name = col['name'] as String;
            final type = col['type'] as String;
            final notNull = col['notnull'] == 1;
            final pk = col['pk'] == 1;
            final defaultValue = col['dflt_value'];

            final nullStr = notNull ? 'NO' : 'YES';
            final pkStr = pk ? '✓ PK' : '';
            final defaultStr = defaultValue?.toString() ?? '';

            ConsoleUtils.tableRow([name, type, nullStr, pkStr, defaultStr], widths);
          }

          // Get indexes
          final indexes = db.select('PRAGMA index_list("$tableName")');
          if (indexes.isNotEmpty) {
            print('${ConsoleUtils.gray}  Indexes:${ConsoleUtils.reset}');
            for (final idx in indexes) {
              final indexName = idx['name'] as String;
              final unique = idx['unique'] == 1;
              final uniqueStr = unique ? ' (UNIQUE)' : '';

              // Get index columns
              final indexInfo = db.select('PRAGMA index_info("$indexName")');
              final indexCols = indexInfo.map((r) => r['name']).join(', ');

              print('    • $indexName: $indexCols$uniqueStr');
            }
          }

          // Get foreign keys
          final foreignKeys = db.select('PRAGMA foreign_key_list("$tableName")');
          if (foreignKeys.isNotEmpty) {
            print('${ConsoleUtils.gray}  Foreign Keys:${ConsoleUtils.reset}');
            for (final fk in foreignKeys) {
              final from = fk['from'] as String;
              final toTable = fk['table'] as String;
              final to = fk['to'] as String;
              print('    • $from → $toTable($to)');
            }
          }

          print('');
        } else {
          // Compact mode: just list columns
          final colNames = columns.map((c) => c['name'] as String).join(', ');
          print('  ${ConsoleUtils.gray}$colNames${ConsoleUtils.reset}');
          print('');
        }
      }

      // If specific table was requested but not found
      if (specificTable != null) {
        final found = tables.any((t) => t['name'] == specificTable);
        if (!found) {
          ConsoleUtils.error('Table "$specificTable" not found');
          print('');
          print('Available tables:');
          for (final t in tables) {
            print('  • ${t['name']}');
          }
          db.close();
          return 1;
        }
      }

      db.close();
      return 0;
    } catch (e) {
      ConsoleUtils.error('Failed to read database: $e');
      return 1;
    }
  }
}
