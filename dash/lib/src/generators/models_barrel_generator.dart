import 'package:dash/src/generators/schema_parser.dart';

/// Generates a barrel file (models.dart) that exports all models
/// and provides a `registerAllModels()` function.
class ModelsBarrelGenerator {
  final List<ParsedSchema> schemas;
  final String packageName;

  ModelsBarrelGenerator(this.schemas, {required this.packageName});

  /// Generate the models.dart barrel file content.
  String generate() {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated barrel file for all models');
    buffer.writeln();

    final sortedSchemas = List<ParsedSchema>.from(schemas)..sort((a, b) => a.modelName.compareTo(b.modelName));

    // Import models
    for (final schema in sortedSchemas) {
      final fileName = _toSnakeCase(schema.modelName);
      buffer.writeln("import 'package:$packageName/models/$fileName.dart';");
    }

    // Import resources
    for (final schema in sortedSchemas) {
      final fileName = _toSnakeCase(schema.modelName);
      buffer.writeln("import 'package:$packageName/resources/${fileName}_resource.dart';");
    }
    buffer.writeln();

    // Exports - models
    for (final schema in sortedSchemas) {
      final fileName = _toSnakeCase(schema.modelName);
      buffer.writeln("export 'package:$packageName/models/$fileName.dart';");
    }

    // Exports - resources
    for (final schema in sortedSchemas) {
      final fileName = _toSnakeCase(schema.modelName);
      buffer.writeln("export 'package:$packageName/resources/${fileName}_resource.dart';");
    }
    buffer.writeln();

    // registerAllModels function
    buffer.writeln('/// Registers all generated models with their resources.');
    buffer.writeln('///');
    buffer.writeln('/// This function registers each model with its metadata and');
    buffer.writeln('/// associates it with its corresponding Resource class.');
    buffer.writeln('///');
    buffer.writeln('/// Example:');
    buffer.writeln('/// ```dart');
    buffer.writeln('/// void main() {');
    buffer.writeln('///   registerAllModels();');
    buffer.writeln('///   // ... rest of your app');
    buffer.writeln('/// }');
    buffer.writeln('/// ```');
    buffer.writeln('void registerAllModels() {');

    for (final schema in sortedSchemas) {
      final modelName = schema.modelName;
      buffer.writeln('  $modelName.register(${modelName}Resource.new);');
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }
}
