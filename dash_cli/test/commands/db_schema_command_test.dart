import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('DbSchemaCommand', () {
    late Directory tempDir;
    late String dbPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dash_cli_db_test_');
      dbPath = '${tempDir.path}/test.db';

      // Create a test database with some tables
      final db = sqlite3.open(dbPath);

      db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          created_at TEXT
        )
      ''');

      db.execute('''
        CREATE TABLE posts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT,
          user_id INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');

      // Insert some test data
      db.execute("INSERT INTO users (name, email) VALUES ('Test User', 'test@example.com')");
      db.execute("INSERT INTO posts (title, content, user_id) VALUES ('Test Post', 'Content', 1)");

      db.close();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('can read table list from database', () {
      final db = sqlite3.open(dbPath);
      final tables = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
      );

      expect(tables, hasLength(2));
      expect(tables.map((t) => t['name']), containsAll(['users', 'posts']));

      db.close();
    });

    test('can read column info from table', () {
      final db = sqlite3.open(dbPath);
      final columns = db.select('PRAGMA table_info("users")');

      expect(columns, hasLength(4));

      final names = columns.map((c) => c['name'] as String).toList();
      expect(names, ['id', 'name', 'email', 'created_at']);

      final emailCol = columns.firstWhere((c) => c['name'] == 'email');
      expect(emailCol['notnull'], 1);

      db.close();
    });

    test('can read row count from table', () {
      final db = sqlite3.open(dbPath);
      final count = db.select('SELECT COUNT(*) as count FROM users');

      expect(count.first['count'], 1);

      db.close();
    });
  });
}
