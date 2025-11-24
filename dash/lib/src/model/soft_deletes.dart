/// Mixin for adding soft delete functionality to models.
///
/// When a model uses soft deletes, the delete() method will set a timestamp
/// instead of actually removing the record from the database.
///
/// Example:
/// ```dart
/// class User extends Model with SoftDeletes {
///   int? id;
///   String? name;
///   DateTime? deletedAt;
///
///   @override
///   String get deletedAtColumn => 'deleted_at';
/// }
///
/// // Usage:
/// await user.delete(); // Sets deleted_at timestamp
/// await user.restore(); // Clears deleted_at
/// await user.forceDelete(); // Actually deletes the record
///
/// // Querying:
/// final active = await User.query().get(); // Excludes soft-deleted
/// final all = await User.query().withTrashed().get(); // Includes soft-deleted
/// final trashed = await User.query().onlyTrashed().get(); // Only soft-deleted
/// ```
mixin SoftDeletes {
  /// The name of the "deleted at" column.
  String get deletedAtColumn => 'deleted_at';

  /// Gets the deleted at timestamp.
  DateTime? get deletedAt;

  /// Sets the deleted at timestamp.
  set deletedAt(DateTime? value);

  /// Determines if the model has been soft deleted.
  bool get isTrashed => deletedAt != null;

  /// Performs a soft delete on the model.
  Future<bool> softDelete() async {
    // This will be implemented by the Model class
    throw UnimplementedError('softDelete must be implemented by Model class');
  }

  /// Restores a soft deleted model.
  Future<bool> restore() async {
    // This will be implemented by the Model class
    throw UnimplementedError('restore must be implemented by Model class');
  }

  /// Permanently deletes the model from the database.
  Future<bool> forceDelete() async {
    // This will be implemented by the Model class
    throw UnimplementedError('forceDelete must be implemented by Model class');
  }
}
