/// Schema definition classes for database migrations.
///
/// These classes provide a database-agnostic way to represent
/// table structures for automatic migrations.
library;

/// Represents a database column type.
enum ColumnType { integer, text, real, blob, boolean, datetime }

/// Represents a single column in a database table.
class ColumnDefinition {
  /// The name of the column.
  final String name;

  /// The data type of the column.
  final ColumnType type;

  /// Whether the column is the primary key.
  final bool isPrimaryKey;

  /// Whether the column is auto-incrementing.
  final bool autoIncrement;

  /// Whether the column can be null.
  final bool nullable;

  /// Default value for the column.
  final dynamic defaultValue;

  /// Whether the column is unique.
  final bool unique;

  const ColumnDefinition({
    required this.name,
    required this.type,
    this.isPrimaryKey = false,
    this.autoIncrement = false,
    this.nullable = true,
    this.defaultValue,
    this.unique = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumnDefinition &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          isPrimaryKey == other.isPrimaryKey &&
          autoIncrement == other.autoIncrement &&
          nullable == other.nullable &&
          defaultValue == other.defaultValue &&
          unique == other.unique;

  @override
  int get hashCode =>
      name.hashCode ^
      type.hashCode ^
      isPrimaryKey.hashCode ^
      autoIncrement.hashCode ^
      nullable.hashCode ^
      defaultValue.hashCode ^
      unique.hashCode;

  @override
  String toString() {
    return 'ColumnDefinition(name: $name, type: $type, isPrimaryKey: $isPrimaryKey, '
        'autoIncrement: $autoIncrement, nullable: $nullable, defaultValue: $defaultValue, '
        'unique: $unique)';
  }

  /// Creates a copy of this column definition with optional modifications.
  ColumnDefinition copyWith({
    String? name,
    ColumnType? type,
    bool? isPrimaryKey,
    bool? autoIncrement,
    bool? nullable,
    dynamic defaultValue,
    bool? unique,
  }) {
    return ColumnDefinition(
      name: name ?? this.name,
      type: type ?? this.type,
      isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
      autoIncrement: autoIncrement ?? this.autoIncrement,
      nullable: nullable ?? this.nullable,
      defaultValue: defaultValue ?? this.defaultValue,
      unique: unique ?? this.unique,
    );
  }
}

/// Represents a database index definition.
class IndexDefinition {
  /// The name of the index.
  final String name;

  /// The columns included in the index.
  final List<String> columns;

  /// Whether this is a unique index.
  final bool unique;

  const IndexDefinition({required this.name, required this.columns, this.unique = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndexDefinition &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          _listEquals(columns, other.columns) &&
          unique == other.unique;

  @override
  int get hashCode => name.hashCode ^ columns.hashCode ^ unique.hashCode;

  @override
  String toString() {
    return 'IndexDefinition(name: $name, columns: $columns, unique: $unique)';
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Represents a pivot table schema for many-to-many relationships.
///
/// Pivot tables store the relationships between two models.
/// For example, a Post hasMany Tag relationship would have a
/// pivot table `post_tag` with columns `post_id` and `tag_id`.
class PivotTableSchema {
  /// The name of the pivot table (e.g., 'post_tag').
  final String name;

  /// The first model's table name (e.g., 'posts').
  final String localTable;

  /// The second model's table name (e.g., 'tags').
  final String relatedTable;

  /// The column name for the first model's foreign key (e.g., 'post_id').
  final String localKeyColumn;

  /// The column name for the second model's foreign key (e.g., 'tag_id').
  final String relatedKeyColumn;

  /// The column type for the local key (usually matches the primary key type).
  final ColumnType localKeyType;

  /// The column type for the related key (usually matches the primary key type).
  final ColumnType relatedKeyType;

  const PivotTableSchema({
    required this.name,
    required this.localTable,
    required this.relatedTable,
    required this.localKeyColumn,
    required this.relatedKeyColumn,
    this.localKeyType = ColumnType.integer,
    this.relatedKeyType = ColumnType.integer,
  });

  /// Generates a TableSchema for this pivot table.
  TableSchema toTableSchema() {
    return TableSchema(
      name: name,
      columns: [
        ColumnDefinition(name: localKeyColumn, type: localKeyType, nullable: false),
        ColumnDefinition(name: relatedKeyColumn, type: relatedKeyType, nullable: false),
      ],
      indexes: [
        // Composite unique index to prevent duplicate relations
        IndexDefinition(name: 'idx_${name}_unique', columns: [localKeyColumn, relatedKeyColumn], unique: true),
        // Index for looking up by local key
        IndexDefinition(name: 'idx_${name}_$localKeyColumn', columns: [localKeyColumn]),
        // Index for looking up by related key
        IndexDefinition(name: 'idx_${name}_$relatedKeyColumn', columns: [relatedKeyColumn]),
      ],
    );
  }

  /// Generates the pivot table name from two table names.
  ///
  /// The names are sorted alphabetically and joined with underscore.
  /// Both names are converted to singular form.
  static String generatePivotTableName(String table1, String table2) {
    final singular1 = _singularize(table1);
    final singular2 = _singularize(table2);
    final sorted = [singular1, singular2]..sort();
    return sorted.join('_');
  }

  /// Simple singularization (removes trailing 's').
  static String _singularize(String table) {
    if (table.endsWith('ies')) {
      return '${table.substring(0, table.length - 3)}y';
    }
    if (table.endsWith('s') && !table.endsWith('ss')) {
      return table.substring(0, table.length - 1);
    }
    return table;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PivotTableSchema &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          localTable == other.localTable &&
          relatedTable == other.relatedTable;

  @override
  int get hashCode => name.hashCode ^ localTable.hashCode ^ relatedTable.hashCode;

  @override
  String toString() {
    return 'PivotTableSchema(name: $name, localTable: $localTable, relatedTable: $relatedTable)';
  }
}

/// Represents a database table schema.
class TableSchema {
  /// The name of the table.
  final String name;

  /// The columns in the table.
  final List<ColumnDefinition> columns;

  /// The indexes on the table.
  final List<IndexDefinition> indexes;

  /// Pivot tables associated with this model's hasMany relationships.
  final List<PivotTableSchema> pivotTables;

  const TableSchema({required this.name, required this.columns, this.indexes = const [], this.pivotTables = const []});

  /// Gets a column by name.
  ColumnDefinition? getColumn(String name) {
    try {
      return columns.firstWhere((col) => col.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Checks if a column exists in the table.
  bool hasColumn(String name) {
    return columns.any((col) => col.name == name);
  }

  /// Gets the primary key column, if any.
  ColumnDefinition? get primaryKey {
    try {
      return columns.firstWhere((col) => col.isPrimaryKey);
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableSchema &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          _listEquals(columns, other.columns) &&
          _listEquals(indexes, other.indexes);

  @override
  int get hashCode => name.hashCode ^ columns.hashCode ^ indexes.hashCode;

  @override
  String toString() {
    return 'TableSchema(name: $name, columns: ${columns.length})';
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
