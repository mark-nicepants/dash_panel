/// Runtime types for Dash models.
///
/// These types are used at runtime for relationship metadata
/// and model introspection. Model code generation is handled
/// by YAML schemas, not annotations.
library;

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

  /// For hasMany relationships, the pivot table name.
  /// Null for belongsTo and hasOne relationships.
  final String? pivotTable;

  /// For hasMany relationships, the local key column in the pivot table.
  /// E.g., for Post hasMany Tag, this would be 'post_id'.
  final String? pivotLocalKey;

  /// For hasMany relationships, the related key column in the pivot table.
  /// E.g., for Post hasMany Tag, this would be 'tag_id'.
  final String? pivotRelatedKey;

  const RelationshipMeta({
    required this.name,
    required this.type,
    required this.foreignKey,
    required this.relatedKey,
    required this.relatedModelType,
    this.pivotTable,
    this.pivotLocalKey,
    this.pivotRelatedKey,
  });

  /// Whether this is a many-to-many relationship using a pivot table.
  bool get usesPivotTable => type == RelationshipType.hasMany && pivotTable != null;
}
