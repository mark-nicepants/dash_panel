/// Annotations for Dash model code generation.
///
/// These annotations are used to mark classes and fields for automatic
/// code generation, eliminating boilerplate in model definitions.
library;

/// Marks a class as a Dash model.
///
/// Example:
/// ```dart
/// @DashModel(table: 'users')
/// class User {
///   @PrimaryKey()
///   int? id;
///
///   @Column()
///   String? name;
/// }
/// ```
class DashModel {
  /// The database table name for this model.
  final String table;

  /// Whether to automatically manage created_at and updated_at timestamps.
  final bool timestamps;

  /// The name of the created_at column.
  final String createdAtColumn;

  /// The name of the updated_at column.
  final String updatedAtColumn;

  const DashModel({
    required this.table,
    this.timestamps = true,
    this.createdAtColumn = 'created_at',
    this.updatedAtColumn = 'updated_at',
  });
}

/// Marks a field as the primary key.
///
/// Example:
/// ```dart
/// @PrimaryKey()
/// int? id;
/// ```
class PrimaryKey {
  /// The column name in the database.
  /// If null, the field name will be converted to snake_case.
  final String? name;

  /// Whether the key is auto-incrementing.
  final bool autoIncrement;

  const PrimaryKey({this.name, this.autoIncrement = true});
}

/// Marks a field as a database column.
///
/// Example:
/// ```dart
/// @Column(name: 'user_name')
/// String? name;
///
/// @Column(nullable: false)
/// String email;
/// ```
class Column {
  /// The column name in the database.
  /// If null, the field name will be converted to snake_case.
  final String? name;

  /// Whether the column can be null.
  /// This is primarily for documentation; nullability is determined by Dart's type system.
  final bool nullable;

  const Column({this.name, this.nullable = true});
}

/// Marks a field as a BelongsTo relationship.
///
/// Example:
/// ```dart
/// @BelongsTo(foreignKey: 'user_id')
/// User? author;
/// ```
class BelongsTo {
  /// The foreign key column name in the current table.
  final String foreignKey;

  /// The local key column name in the related table.
  final String ownerKey;

  const BelongsTo({required this.foreignKey, this.ownerKey = 'id'});
}

/// Marks a field as a HasMany relationship.
///
/// Example:
/// ```dart
/// @HasMany(foreignKey: 'user_id')
/// List<Post>? posts;
/// ```
class HasMany {
  /// The foreign key column name in the related table.
  final String foreignKey;

  /// The local key column name in the current table.
  final String localKey;

  const HasMany({required this.foreignKey, this.localKey = 'id'});
}

/// Marks a field as a HasOne relationship.
///
/// Example:
/// ```dart
/// @HasOne(foreignKey: 'user_id')
/// Profile? profile;
/// ```
class HasOne {
  /// The foreign key column name in the related table.
  final String foreignKey;

  /// The local key column name in the current table.
  final String localKey;

  const HasOne({required this.foreignKey, this.localKey = 'id'});
}

/// Adds validation rules to a field.
///
/// Example:
/// ```dart
/// @Validate([Required(), Email()])
/// String? email;
/// ```
class Validate {
  final List<String> rules;

  const Validate(this.rules);
}

/// Types of relationships between models.
enum RelationshipType { belongsTo, hasOne, hasMany }

/// Metadata about a model relationship.
///
/// This class holds runtime information about relationships
/// that is used for eager loading and relation resolution.
class RelationshipMeta {
  /// The name of the relationship field (e.g., 'author').
  final String name;

  /// The type of relationship.
  final RelationshipType type;

  /// The foreign key column name.
  final String foreignKey;

  /// The related key column (owner key for BelongsTo, local key for HasOne/HasMany).
  final String relatedKey;

  /// The type of the related model as a string.
  final String relatedModelType;

  const RelationshipMeta({
    required this.name,
    required this.type,
    required this.foreignKey,
    required this.relatedKey,
    required this.relatedModelType,
  });
}
