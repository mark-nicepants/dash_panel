/// Exception thrown when model validation fails.
class ValidationException implements Exception {
  final Map<String, List<String>> errors;

  ValidationException(this.errors);

  @override
  String toString() {
    final buffer = StringBuffer('Validation failed:\n');
    errors.forEach((field, messages) {
      buffer.writeln('  $field: ${messages.join(', ')}');
    });
    return buffer.toString();
  }
}

/// Base class for validation rules.
abstract class ValidationRule {
  /// Validates the given value.
  /// Returns null if valid, or an error message if invalid.
  String? validate(String field, dynamic value);
}

/// Rule that requires a value to be present.
class Required extends ValidationRule {
  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '' || (value is List && value.isEmpty)) {
      return 'The $field field is required.';
    }
    return null;
  }
}

/// Rule that validates an email address.
class Email extends ValidationRule {
  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '') return null; // Use Required for non-null
    if (value is! String) return 'The $field must be a string.';
    if (!_emailRegex.hasMatch(value)) {
      return 'The $field must be a valid email address (Value: $value).';
    }
    return null;
  }
}

/// Rule that validates a minimum length.
class MinLength extends ValidationRule {
  final int min;

  MinLength(this.min);

  @override
  String? validate(String field, dynamic value) {
    if (value == null) return null;
    final length = value is String ? value.length : value.toString().length;
    if (length < min) {
      return 'The $field must be at least $min characters.';
    }
    return null;
  }
}

/// Rule that validates a maximum length.
class MaxLength extends ValidationRule {
  final int max;

  MaxLength(this.max);

  @override
  String? validate(String field, dynamic value) {
    if (value == null) return null;
    final length = value is String ? value.length : value.toString().length;
    if (length > max) {
      return 'The $field must not exceed $max characters.';
    }
    return null;
  }
}

/// Rule that validates a numeric value.
class Numeric extends ValidationRule {
  @override
  String? validate(String field, dynamic value) {
    if (value == null) return null;
    if (value is num) return null;
    if (value is String && num.tryParse(value) != null) return null;
    return 'The $field must be a number.';
  }
}

/// Rule that validates a minimum numeric value.
class Min extends ValidationRule {
  final num min;

  Min(this.min);

  @override
  String? validate(String field, dynamic value) {
    if (value == null) return null;
    num? numValue;
    if (value is num) {
      numValue = value;
    } else if (value is String) {
      numValue = num.tryParse(value);
    }
    if (numValue == null) return 'The $field must be a number.';
    if (numValue < min) {
      return 'The $field must be at least $min.';
    }
    return null;
  }
}

/// Rule that validates a maximum numeric value.
class Max extends ValidationRule {
  final num max;

  Max(this.max);

  @override
  String? validate(String field, dynamic value) {
    if (value == null) return null;
    num? numValue;
    if (value is num) {
      numValue = value;
    } else if (value is String) {
      numValue = num.tryParse(value);
    }
    if (numValue == null) return 'The $field must be a number.';
    if (numValue > max) {
      return 'The $field must not exceed $max.';
    }
    return null;
  }
}

/// Rule that validates a value is in a list of allowed values.
class InList extends ValidationRule {
  final List<dynamic> allowed;

  InList(this.allowed);

  @override
  String? validate(String field, dynamic value) {
    if (value == null) return null;
    if (!allowed.contains(value)) {
      return 'The $field must be one of: ${allowed.join(', ')}.';
    }
    return null;
  }
}

/// Rule that validates a value matches a regex pattern.
class Pattern extends ValidationRule {
  final RegExp pattern;
  final String? message;

  Pattern(this.pattern, {this.message});

  @override
  String? validate(String field, dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    if (!pattern.hasMatch(str)) {
      return message ?? 'The $field format is invalid.';
    }
    return null;
  }
}

/// Rule that validates a value is unique in the database.
class Unique extends ValidationRule {
  final String table;
  final String column;
  final dynamic ignoreId;
  final String? ignoreColumn;

  Unique(this.table, this.column, {this.ignoreId, this.ignoreColumn = 'id'});

  @override
  String? validate(String field, dynamic value) {
    // This needs database access, so it's marked for async implementation
    // For now, return null (will be implemented in Model class)
    return null;
  }
}
