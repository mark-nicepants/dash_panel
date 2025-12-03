import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dash_cli/src/utils/console_utils.dart';
import 'package:sqlite3/sqlite3.dart';

/// Clear all data from database tables.
///
/// Usage:
///   dash db:clear [options]
///
/// Options:
///   -d, --database    Path to SQLite database file
///   -t, --table       Clear only specific table
///   --force           Skip confirmation prompt
class DbClearCommand extends Command<int> {
  DbClearCommand() {
    argParser
      ..addOption('database', abbr: 'd', help: 'Path to SQLite database file', defaultsTo: 'storage/app.db')
      ..addOption('table', abbr: 't', help: 'Clear only specific table')
      ..addFlag('force', abbr: 'f', help: 'Skip confirmation prompt', defaultsTo: false);
  }
  @override
  final String name = 'db:clear';

  @override
  final String description = 'Clear all data from database tables (keeps table structure)';

  @override
  final List<String> aliases = ['clear'];

  @override
  Future<int> run() async {
    final databasePath = argResults!['database'] as String;
    final specificTable = argResults!['table'] as String?;
    final force = argResults!['force'] as bool;

    ConsoleUtils.header('🗑️  Database Cleaner');

    // Check database exists
    if (!File(databasePath).existsSync()) {
      ConsoleUtils.error('Database not found: $databasePath');
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

      // Filter to specific table if provided
      final tablesToClear = specificTable != null ? tables.where((t) => t['name'] == specificTable).toList() : tables;

      if (tablesToClear.isEmpty) {
        ConsoleUtils.error('Table "$specificTable" not found');
        print('');
        print('Available tables:');
        for (final t in tables) {
          print('  • ${t['name']}');
        }
        db.close();
        return 1;
      }

      // Show what will be cleared
      ConsoleUtils.info('Database: $databasePath');
      print('');
      print('Tables to clear:');

      var totalRows = 0;
      for (final table in tablesToClear) {
        final tableName = table['name'] as String;
        final count = db.select('SELECT COUNT(*) as count FROM "$tableName"');
        final rows = count.first['count'] as int;
        totalRows += rows;
        print('  • $tableName ($rows rows)');
      }
      print('');
      print('${ConsoleUtils.yellow}Total: $totalRows rows will be deleted${ConsoleUtils.reset}');
      print('');

      // Confirm unless --force
      if (!force) {
        final confirmed = ConsoleUtils.confirm('Are you sure you want to delete all data?');
        if (!confirmed) {
          print('');
          ConsoleUtils.info('Operation cancelled');
          db.close();
          return 0;
        }
      }

      print('');

      // Disable foreign key checks temporarily
      db.execute('PRAGMA foreign_keys = OFF');

      // Clear tables
      var clearedRows = 0;
      for (final table in tablesToClear) {
        final tableName = table['name'] as String;

        try {
          final countBefore = db.select('SELECT COUNT(*) as count FROM "$tableName"');
          final rowsBefore = countBefore.first['count'] as int;

          db.execute('DELETE FROM "$tableName"');

          clearedRows += rowsBefore;
          ConsoleUtils.success('Cleared $tableName ($rowsBefore rows)');
        } catch (e) {
          ConsoleUtils.error('Failed to clear $tableName: $e');
        }
      }

      // Re-enable foreign key checks
      db.execute('PRAGMA foreign_keys = ON');

      // Vacuum to reclaim space
      try {
        db.execute('VACUUM');
      } catch (_) {
        // VACUUM might fail if in transaction
      }

      db.close();

      print('');
      ConsoleUtils.line();
      ConsoleUtils.success('Cleared $clearedRows total rows from ${tablesToClear.length} table(s)');
      print('');

      return 0;
    } catch (e) {
      ConsoleUtils.error('Database error: $e');
      return 1;
    }
  }
}
