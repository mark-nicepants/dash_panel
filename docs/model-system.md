# Model System (Eloquent-like ORM)

## Overview

Dash includes a powerful Model system inspired by Laravel's Eloquent ORM. Models provide an elegant, type-safe way to interact with database tables, hiding database complexity behind intuitive classes.

## Core Concepts

### Model Class

Every model represents a database table and extends the `Model` base class:

```dart
class User extends Model {
  int? id;
  String? name;
  String? email;
  String? role;
  DateTime? createdAt;

  User({this.id, this.name, this.email, this.role, this.createdAt});

  @override
  String get table => 'users';

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic value) => id = value as int?;

  @override
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'role': role,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  @override
  void fromMap(Map<String, dynamic> map) {
    id = map['id'] as int?;
    name = map['name'] as String?;
    email = map['email'] as String?;
    role = map['role'] as String?;
    if (map['created_at'] != null) {
      createdAt = DateTime.parse(map['created_at'] as String);
    }
  }

  static ModelQueryBuilder<User> query() {
    return ModelQueryBuilder<User>(
      Model.connector,
      modelFactory: () => User(),
    ).table('users');
  }

  static Future<User?> find(int id) => query().find(id);
  static Future<List<User>> all() => query().getTyped();
}
```

## Setup

Before using models, set the database connector:

```dart
// In your main() function after panel boots
Model.setConnector(dbConnector);
```

## Querying Models

### Retrieving All Records

```dart
final users = await User.all();
// Returns: List<User>
```

### Finding by Primary Key

```dart
final user = await User.find(1);
// Returns: User? (null if not found)
```

### Query Builder

Build complex queries with a fluent API:

```dart
// Where clause
final admins = await User.query()
  .where('role', 'admin')
  .getTyped();

// Multiple conditions
final activeAdmins = await User.query()
  .where('role', 'admin')
  .where('status', 'active')
  .getTyped();

// Ordering
final recentUsers = await User.query()
  .orderBy('created_at', 'DESC')
  .limit(10)
  .getTyped();

// Where IN
final specificUsers = await User.query()
  .whereIn('id', [1, 2, 3])
  .getTyped();

// Get first result
final firstAdmin = await User.query()
  .where('role', 'admin')
  .firstTyped();
```

### Custom Query Methods

Add custom query methods to your models:

```dart
class Post extends Model {
  // ... model definition ...
  
  static Future<List<Post>> published() {
    return query().where('status', 'published').getTyped();
  }
  
  static Future<List<Post>> drafts() {
    return query().where('status', 'draft').getTyped();
  }
  
  static Future<List<Post>> byAuthor(int userId) {
    return query().where('user_id', userId).getTyped();
  }
}

// Usage
final publishedPosts = await Post.published();
final myDrafts = await Post.drafts();
```

## Creating Records

### Option 1: Create and Save

```dart
final user = User(
  name: 'John Doe',
  email: 'john@example.com',
  role: 'user',
);

await user.save();
print(user.id); // Auto-set after save
```

### Option 2: Mass Assignment

```dart
final user = User();
user.fromMap({
  'name': 'John Doe',
  'email': 'john@example.com',
  'role': 'user',
});
await user.save();
```

## Updating Records

### Update Instance

```dart
final user = await User.find(1);
if (user != null) {
  user.name = 'Jane Doe';
  user.role = 'admin';
  await user.save();
}
```

### Update with Map

```dart
final user = await User.find(1);
if (user != null) {
  await user.update({
    'name': 'Jane Doe',
    'role': 'admin',
  });
}
```

## Deleting Records

```dart
final user = await User.find(1);
if (user != null) {
  await user.delete();
}
```

## Refreshing Models

Reload the model from the database:

```dart
final user = await User.find(1);
// ... time passes, data might change ...
await user.refresh();
```

## Model Configuration

### Table Name

```dart
@override
String get table => 'users';
```

### Primary Key

```dart
@override
String get primaryKey => 'id';

@override
bool get incrementing => true;
```

### Timestamps

Enable/disable automatic timestamp handling:

```dart
@override
bool get timestamps => true; // default

@override
String get createdAtColumn => 'created_at';

@override
String get updatedAtColumn => 'updated_at';
```

## Relationships

### BelongsTo Example

```dart
class Post extends Model {
  int? userId;
  User? author;
  
  Future<void> loadAuthor() async {
    if (userId != null) {
      author = await User.find(userId!);
    }
  }
}

// Usage
final post = await Post.find(1);
await post.loadAuthor();
print('Author: ${post.author?.name}');
```

### HasMany Example (Future Enhancement)

```dart
class User extends Model {
  Future<List<Post>> posts() async {
    return Post.query().where('user_id', id).getTyped();
  }
}

// Usage
final user = await User.find(1);
final userPosts = await user.posts();
```

## Integration with Resources

Resources can now be typed with their model:

```dart
class UserResource extends Resource<User> {
  @override
  Type get model => User;
  
  @override
  String get label => 'Users';
  
  @override
  String get singularLabel => 'User';
}
```

## Benefits

✅ **Type Safety** - Full Dart typing, compile-time checks
✅ **Eloquent Syntax** - Familiar to Laravel/PHP developers
✅ **Hidden Complexity** - Database operations abstracted away
✅ **Fluent Queries** - Readable, chainable query building
✅ **Auto-Casting** - Automatic type conversion (int, String, DateTime, etc.)
✅ **IDE Support** - Full autocomplete and IntelliSense
✅ **Testable** - Easy to mock and test

## Comparison

### Before (Raw Queries)

```dart
final results = await panel.query()
  .table('users')
  .where('role', 'admin')
  .get();

for (final row in results) {
  print('${row['name']} - ${row['email']}');
}
```

### After (Models)

```dart
final users = await User.query()
  .where('role', 'admin')
  .getTyped();

for (final user in users) {
  print('${user.name} - ${user.email}'); // Type-safe!
}
```

## Advanced Features

### Counting

```dart
final count = await User.query()
  .where('role', 'admin')
  .count();
```

### Plucking Values

```dart
final email = await User.query()
  .where('id', 1)
  .value<String>('email');
```

### Complex Queries

```dart
final results = await User.query()
  .where('status', 'active')
  .whereIn('role', ['admin', 'editor'])
  .whereNotNull('email_verified_at')
  .orderBy('created_at', 'DESC')
  .limit(20)
  .offset(10)
  .getTyped();
```

## Testing Example

All Model features are demonstrated in `dash_example/lib/main.dart`:

- ✅ Query all users
- ✅ Find by ID
- ✅ Where clauses
- ✅ Custom query methods
- ✅ Create new records
- ✅ Update records
- ✅ Delete records
- ✅ Relationship loading
- ✅ Counting records

Run the example:
```bash
cd dash_example
dart run lib/main.dart
```

## Future Enhancements

- **Field classes** with validation and casting
- **Eager loading** for relationships
- **Scopes** for reusable queries
- **Events** (creating, created, updating, updated, etc.)
- **Soft deletes**
- **Observers** for model events
- **Factories** for testing
- **Seeders** integration

---

The Model system brings Laravel's Eloquent elegance to Dart! 🚀
