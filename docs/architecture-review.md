# Dash Architecture Review & Improvement Plan

## Current State Analysis

### ✅ What's Working Well

1. **Clean Query Syntax**
   ```dart
   final users = await User.query().where('role', 'admin').get();
   final user = await User.find(1);
   ```
   - Eloquent-like, intuitive
   - Type-safe results
   - Chainable methods

2. **Database Abstraction**
   - Connector pattern allows multiple DB types
   - QueryBuilder hides SQL complexity
   - Transactions supported

3. **Model System**
   - Static methods hide complexity
   - Instance methods (save, delete) are intuitive
   - Relationships possible (though manual)

---

## 🔧 Areas for Improvement

### 1. **Model Boilerplate (HIGH PRIORITY)**

**Current Problem:**
```dart
class User extends Model {
  int? id;
  String? name;
  String? email;
  
  User({this.id, this.name, this.email});
  
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
    };
  }
  
  @override
  void fromMap(Map<String, dynamic> map) {
    id = map['id'] as int?;
    name = map['name'] as String?;
    email = map['email'] as String?;
  }
  
  static ModelQueryBuilder<User> query() {
    return ModelQueryBuilder<User>(
      Model.connector,
      modelFactory: () => User(),
    ).table('users');
  }
}
```

**Problems:**
- 70+ lines for a simple model
- Repetitive `toMap()`/`fromMap()` for every field
- Manual type casting everywhere
- Easy to make mistakes (typos in column names)
- DateTime parsing is verbose

**Proposed Solution - Annotation-based Code Generation:**

```dart
@Model(table: 'users')
class User {
  @PrimaryKey()
  int? id;
  
  @Column()
  String? name;
  
  @Column()
  String? email;
  
  @Column()
  String? role;
  
  @Column(name: 'created_at')
  DateTime? createdAt;
}
```

Generated code handles:
- `toMap()` / `fromMap()`
- `getKey()` / `setKey()`
- `query()` method
- Type casting and DateTime parsing

**Alternative (No Code Gen) - Reflection-based:**
```dart
class User extends Model {
  @primaryKey
  int? id;
  
  String? name;
  String? email;
  String? role;
  
  @column('created_at')
  DateTime? createdAt;
  
  @override
  String get table => 'users';
}
```
Use mirrors or manual registration to auto-generate maps.

---

### 2. **Static Query Method Duplication**

**Current Problem:**
Every model must define:
```dart
static ModelQueryBuilder<User> query() {
  return ModelQueryBuilder<User>(
    Model.connector,
    modelFactory: () => User(),
  ).table('users');
}

static Future<User?> find(int id) => query().find(id);
static Future<List<User>> all() => query().get();
```

**Proposed Solution - Mixin:**
```dart
mixin QueryableMixin<T extends Model> on Model {
  static ModelQueryBuilder<T> query<T extends Model>() {
    // Auto-detect table from model
    final instance = _createInstance<T>();
    return ModelQueryBuilder<T>(
      Model.connector,
      modelFactory: () => _createInstance<T>(),
    ).table(instance.table);
  }
}

class User extends Model with QueryableMixin<User> {
  // query() method is automatic!
}
```

Or use a factory registry:
```dart
class User extends Model {
  User._(); // Private constructor
  factory User() => _pool.get() ?? User._();
}

// Usage stays the same
final users = await User.query().get();
```

---

### 3. **Relationship Loading is Too Manual**

**Current Problem:**
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
await post.loadAuthor(); // Manual call
print(post.author?.name);
```

**Proposed Solution - Declarative Relationships:**

```dart
class Post extends Model {
  int? userId;
  
  @BelongsTo(foreignKey: 'userId')
  User? author;
  
  @HasMany(foreignKey: 'postId')
  List<Comment>? comments;
}

// Usage
final post = await Post.query().with(['author', 'comments']).find(1);
print(post.author?.name); // Already loaded!

// Or lazy load
final post = await Post.find(1);
final author = await post.author(); // Returns Future<User?>
```

**Alternative - Property Getters:**
```dart
class Post extends Model {
  int? userId;
  
  Future<User?> get author async => User.find(userId!);
  Future<List<Comment>> get comments async => 
    Comment.query().where('post_id', id).get();
}

// Usage
final author = await post.author;
final comments = await post.comments;
```

---

### 4. **Column Name Mismatch (snake_case vs camelCase)**

**Current Problem:**
```dart
// Database: user_id
// Dart: userId
@override
Map<String, dynamic> toMap() {
  return {
    'user_id': userId,  // Manual mapping
    'created_at': createdAt?.toIso8601String(),
  };
}
```

**Proposed Solution - Auto-conversion:**
```dart
class Model {
  // Built-in snake_case <-> camelCase conversion
  String columnName(String fieldName) => 
    fieldName.replaceAllMapped(
      RegExp(r'[A-Z]'), 
      (m) => '_${m.group(0)!.toLowerCase()}'
    );
}

// Or annotation
class Post extends Model {
  @Column(name: 'user_id')
  int? userId;
}
```

---

### 5. **Type Casting Safety**

**Current Problem:**
```dart
void fromMap(Map<String, dynamic> map) {
  id = map['id'] as int?;  // Crashes if wrong type
  userId = map['user_id'] as int?;
}
```

**Proposed Solution - Safe Casting Helper:**
```dart
abstract class Model {
  T? cast<T>(dynamic value) {
    if (value == null) return null;
    try {
      return value as T;
    } catch (e) {
      // Log warning
      return null;
    }
  }
  
  DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

void fromMap(Map<String, dynamic> map) {
  id = cast<int>(map['id']);
  createdAt = parseDateTime(map['created_at']);
}
```

---

### 6. **Query Scopes (Reusable Queries)**

**Current Problem:**
```dart
// Repeated logic
final admins = await User.query().where('role', 'admin').get();
final activeAdmins = await User.query()
  .where('role', 'admin')
  .where('status', 'active')
  .get();
```

**Proposed Solution - Scopes:**
```dart
class User extends Model {
  // Local scopes
  static ModelQueryBuilder<User> admins() => 
    query().where('role', 'admin');
  
  static ModelQueryBuilder<User> active() => 
    query().where('status', 'active');
}

// Usage
final admins = await User.admins().get();
final activeAdmins = await User.admins().active().get();
```

Or callable scope classes:
```dart
class AdminScope extends QueryScope<User> {
  @override
  void apply(ModelQueryBuilder<User> query) {
    query.where('role', 'admin');
  }
}

// Apply globally
class User extends Model {
  @override
  List<QueryScope> get globalScopes => [AdminScope()];
}
```

---

### 7. **Validation**

**Current Missing Feature:**
```dart
class User extends Model {
  String? email;
  
  // Validation rules
  @override
  Map<String, List<Rule>> get rules => {
    'email': [Required(), Email()],
    'name': [Required(), MinLength(3)],
    'age': [Numeric(), Min(18)],
  };
}

// Usage
final user = User(email: 'invalid');
try {
  await user.save(); // Auto-validates
} on ValidationException catch (e) {
  print(e.errors); // {'email': ['Invalid email format']}
}
```

---

### 8. **Events/Observers**

**Current Missing Feature:**
```dart
class User extends Model {
  @override
  void onCreating() {
    // Hash password, set defaults
    if (password != null) {
      password = hashPassword(password!);
    }
  }
  
  @override
  void onSaved() {
    // Clear cache, send notifications
    cache.clear('users');
  }
}

// Or observers
class UserObserver {
  void creating(User user) { }
  void created(User user) { }
  void updating(User user) { }
  void updated(User user) { }
  void deleting(User user) { }
  void deleted(User user) { }
}

User.observe(UserObserver());
```

---

### 9. **Mass Assignment Protection**

**Current Issue:**
```dart
// Dangerous - user could inject admin role
final user = User();
user.fromMap(request.body); // What if role: 'admin' is in body?
await user.save();
```

**Proposed Solution:**
```dart
class User extends Model {
  @override
  List<String> get fillable => ['name', 'email']; // Whitelist
  
  // Or
  @override
  List<String> get guarded => ['id', 'role']; // Blacklist
}

// Safe
user.fill(request.body); // Only fills whitelisted fields
```

---

### 10. **Soft Deletes**

**Proposed Feature:**
```dart
class User extends Model with SoftDeletes {
  DateTime? deletedAt;
}

// Usage
await user.delete(); // Sets deletedAt
final users = await User.all(); // Excludes soft-deleted
final all = await User.withTrashed().get(); // Includes soft-deleted
await user.restore(); // Undeletes
await user.forceDelete(); // Permanently deletes
```

---

### 11. **Resource Improvements**

**Current Problem:**
```dart
class UserResource extends Resource<User> {
  @override
  Type get model => User;
  
  @override
  String get label => 'Users';
  
  // No actual CRUD wiring!
}
```

**Proposed Solution - Auto CRUD:**
```dart
class UserResource extends Resource<User> {
  @override
  Type get model => User;
  
  // These should be auto-generated from model
  @override
  List<Field> fields() => [
    TextField('name').required(),
    EmailField('email').required(),
    SelectField('role').options(['user', 'admin']),
  ];
  
  // Auto-generate routes:
  // GET /admin/users - index
  // GET /admin/users/create - create form
  // POST /admin/users - store
  // GET /admin/users/:id - show
  // GET /admin/users/:id/edit - edit form
  // PUT /admin/users/:id - update
  // DELETE /admin/users/:id - delete
}
```

---

## 🎯 Priority Implementation Order

### Phase 1 (Foundation) - Week 1-2
1. ✅ Model base class improvements
   - Safe casting helpers
   - Automatic snake_case conversion
   - Helper methods (parseDateTime, etc.)

2. ✅ Query builder enhancements
   - Add `orWhere()`, `whereBetween()`, `whereDate()`
   - Aggregate functions (sum, avg, max, min)
   - Group by, having

### Phase 2 (Developer Experience) - Week 3-4
3. ✅ Query scopes
4. ✅ Relationship system (BelongsTo, HasMany, HasOne)
5. ✅ Events/hooks system

### Phase 3 (Safety & Validation) - Week 5-6
6. ✅ Validation system
7. ✅ Mass assignment protection
8. ✅ Soft deletes mixin

### Phase 4 (Code Generation) - Week 7-8
9. ✅ Build annotations
10. ✅ Code generator for toMap/fromMap
11. ✅ Generate query methods

### Phase 5 (Resource Integration) - Week 9-10
12. ✅ Wire Resources to Models
13. ✅ Auto-generate CRUD routes
14. ✅ Form builders from model fields

---

## 💡 Immediate Quick Wins (Can do now)

### A. Reduce Query Boilerplate
```dart
// Add to Model base class
static ModelQueryBuilder<T> query<T extends Model>() {
  // Auto-detect from runtime type
}
```

### B. Add Helper Methods
```dart
abstract class Model {
  T? getAs<T>(Map map, String key) { }
  DateTime? getDateTime(Map map, String key) { }
  List<T> getList<T>(Map map, String key) { }
}
```

### C. Add Common Query Methods
```dart
class User extends Model {
  static Future<User?> findByEmail(String email) =>
    query().where('email', email).first();
  
  static Future<List<User>> admins() =>
    query().where('role', 'admin').get();
}
```

---

## 📊 Comparison: Before vs After Improvements

### Current
```dart
class User extends Model {
  int? id;
  String? name;
  String? email;
  DateTime? createdAt;
  
  User({this.id, this.name, this.email, this.createdAt});
  
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
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
  
  @override
  void fromMap(Map<String, dynamic> map) {
    id = map['id'] as int?;
    name = map['name'] as String?;
    email = map['email'] as String?;
    if (map['created_at'] != null) {
      createdAt = DateTime.parse(map['created_at'] as String);
    }
  }
  
  static ModelQueryBuilder<User> query() { ... }
  static Future<User?> find(int id) { ... }
  static Future<List<User>> all() { ... }
}
```
**~75 lines**

### After Improvements (Code Gen)
```dart
@model
class User {
  @primaryKey
  int? id;
  
  String? name;
  String? email;
  DateTime? createdAt;
  
  // Everything else auto-generated
}
```
**~10 lines**

### After Improvements (No Code Gen - Helper Methods)
```dart
class User extends ModelBase {
  int? id;
  String? name;
  String? email;
  DateTime? createdAt;
  
  @override
  String get table => 'users';
  
  @override
  String get primaryKey => 'id';
  
  // toMap/fromMap uses reflection or field registry
}
```
**~15-20 lines**

---

## 🚀 Recommended Next Steps

1. **Immediate (This Week)**
   - Add helper methods to Model base class
   - Implement query scopes
   - Add common query builder methods (orWhere, whereBetween, etc.)

2. **Short Term (Next 2 Weeks)**
   - Basic relationship system (BelongsTo, HasMany)
   - Event hooks (creating, created, updating, etc.)
   - Validation framework

3. **Medium Term (Month 2)**
   - Code generation for models
   - Soft deletes
   - Mass assignment protection

4. **Long Term (Month 3+)**
   - Resource CRUD auto-generation
   - Advanced relationships (ManyToMany, polymorphic)
   - Migration system

---

## Consumer-Facing API Goals

The ideal syntax should be:
```dart
// Define model (minimal boilerplate)
@model
class User {
  int? id;
  String name;
  String email;
}

// Query (clean, expressive)
final admins = await User.where('role', 'admin').get();
final user = await User.find(1);

// Relationships (declarative)
final posts = await user.posts;

// Create/Update (intuitive)
final user = User(name: 'John', email: 'john@example.com');
await user.save();

// Validation (automatic)
await user.save(); // Throws ValidationException if invalid
```

Keep all complexity hidden behind clean, intuitive APIs!
