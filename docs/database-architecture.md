# Database System Architecture

## Overview

Dash provides a flexible, connector-based database system that allows you to connect to different database types while maintaining a consistent API.

## Architecture Components

### 1. DatabaseConnector (Abstract Interface)

The base interface that all database connectors must implement:

```dart
abstract class DatabaseConnector {
  Future<void> connect();
  Future<void> close();
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? parameters]);
  Future<int> execute(String sql, [List<dynamic>? parameters]);
  Future<int> insert(String table, Map<String, dynamic> data);
  Future<int> update(String table, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs});
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs});
  Future<void> beginTransaction();
  Future<void> commit();
  Future<void> rollback();
  bool get isConnected;
  String get type;
}
```

### 2. DatabaseConfig

Wraps a connector and provides configuration options:

```dart
final config = DatabaseConfig.using(
  SqliteConnector('app.db'),
  options: {'timeout': 5000},
);
```

### 3. QueryBuilder

Provides a fluent API for building queries:

```dart
final users = await panel.query()
  .table('users')
  .where('role', 'admin')
  .orderBy('created_at', 'DESC')
  .limit(10)
  .get();
```

#### Supported Query Builder Methods

- **Selection**: `select()`, `table()`
- **Where Clauses**: `where()`, `whereIn()`, `whereNull()`, `whereNotNull()`
- **Ordering**: `orderBy()`
- **Limiting**: `limit()`, `offset()`
- **Retrieval**: `get()`, `first()`, `value()`, `count()`
- **Mutations**: `insert()`, `update()`, `delete()`

### 4. SqliteConnector

The SQLite implementation:

```dart
final connector = SqliteConnector('database/app.db');
await connector.connect();

// File-based
SqliteConnector('path/to/db.db')

// In-memory
SqliteConnector(':memory:')
```

## Integration with Panel

The database system is integrated directly into the Panel class:

```dart
final panel = Panel()
  ..database(DatabaseConfig.using(SqliteConnector('app.db')))
  ..boot();

// Use the query builder
final users = await panel.query().table('users').get();
```

## Example Usage

### Basic CRUD Operations

```dart
// Create
final userId = await panel.query()
  .table('users')
  .insert({'name': 'John', 'email': 'john@example.com'});

// Read
final users = await panel.query()
  .table('users')
  .where('email', 'john@example.com')
  .get();

// Update
final updated = await panel.query()
  .table('users')
  .where('id', userId)
  .update({'name': 'John Doe'});

// Delete
final deleted = await panel.query()
  .table('users')
  .where('id', userId)
  .delete();
```

### Advanced Queries

```dart
// Complex WHERE clauses
final results = await panel.query()
  .table('posts')
  .where('status', 'published')
  .whereIn('category_id', [1, 2, 3])
  .whereNotNull('published_at')
  .orderBy('created_at', 'DESC')
  .limit(10)
  .get();

// Counting
final count = await panel.query()
  .table('posts')
  .where('status', 'published')
  .count();

// Getting specific values
final email = await panel.query()
  .table('users')
  .where('id', 1)
  .value<String>('email');
```

### Transactions

```dart
final connector = panel.databaseConfig!.connector;

await connector.beginTransaction();
try {
  await connector.insert('users', {...});
  await connector.insert('profiles', {...});
  await connector.commit();
} catch (e) {
  await connector.rollback();
  rethrow;
}
```

## Future Connectors

The architecture supports adding more database connectors:

- **PostgresConnector** - PostgreSQL support
- **MySqlConnector** - MySQL/MariaDB support
- **MongoConnector** - MongoDB support (NoSQL)
- **FirestoreConnector** - Google Cloud Firestore

Each connector only needs to implement the `DatabaseConnector` interface.

## File Structure

```
dash/lib/src/database/
├── database_connector.dart      # Abstract interface
├── database_config.dart         # Configuration wrapper
├── query_builder.dart           # Fluent query builder
└── connectors/
    └── sqlite_connector.dart    # SQLite implementation
```

## Testing

The example project demonstrates all database features:

```bash
cd dash_example
dart run lib/main.dart
```

This will:
1. Create tables (users, posts)
2. Seed sample data
3. Execute various queries (SELECT, WHERE, UPDATE)
4. Demonstrate query builder features

## Benefits

✅ **Abstraction** - Switch databases without changing application code
✅ **Type-Safe** - Leverages Dart's type system
✅ **Fluent API** - Readable, chainable query building
✅ **Consistent** - Same API across all database types
✅ **Extensible** - Easy to add new connectors
✅ **Transaction Support** - Built-in transaction handling
✅ **Async/Await** - Modern asynchronous patterns
