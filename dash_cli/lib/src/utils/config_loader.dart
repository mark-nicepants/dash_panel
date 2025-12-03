import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Configuration loader for Dash CLI.
///
/// Loads configuration from:
/// 1. dash.yaml in current directory
/// 2. pubspec.yaml (dash section)
/// 3. Command-line arguments (highest priority)
class ConfigLoader {
  /// Load configuration from the current project.
  static DashConfig load({String? configPath}) {
    final cwd = Directory.current.path;

    // Try dash.yaml first
    var dashConfigPath = configPath ?? path.join(cwd, 'dash.yaml');
    if (File(dashConfigPath).existsSync()) {
      return _loadFromFile(dashConfigPath);
    }

    // Try panel.yaml in schemas directory
    dashConfigPath = path.join(cwd, 'schemas', 'panel.yaml');
    if (File(dashConfigPath).existsSync()) {
      return _loadFromFile(dashConfigPath);
    }

    // Try pubspec.yaml
    final pubspecPath = path.join(cwd, 'pubspec.yaml');
    if (File(pubspecPath).existsSync()) {
      final pubspec = _loadYamlFile(pubspecPath);
      if (pubspec != null && pubspec['dash'] != null) {
        return DashConfig.fromYaml(pubspec['dash'] as YamlMap);
      }
    }

    // Return default config
    return DashConfig.defaults();
  }

  static DashConfig _loadFromFile(String filePath) {
    final yaml = _loadYamlFile(filePath);
    if (yaml == null) {
      return DashConfig.defaults();
    }
    return DashConfig.fromYaml(yaml);
  }

  static YamlMap? _loadYamlFile(String filePath) {
    try {
      final content = File(filePath).readAsStringSync();
      return loadYaml(content) as YamlMap?;
    } catch (_) {
      return null;
    }
  }

  /// Find the project root by looking for pubspec.yaml.
  static String? findProjectRoot([String? startPath]) {
    var current = Directory(startPath ?? Directory.current.path);

    while (current.path != current.parent.path) {
      final pubspec = File(path.join(current.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        return current.path;
      }
      current = current.parent;
    }

    return null;
  }

  /// Get the package name from pubspec.yaml.
  static String? getPackageName([String? projectRoot]) {
    final root = projectRoot ?? findProjectRoot();
    if (root == null) return null;

    final pubspecPath = path.join(root, 'pubspec.yaml');
    final yaml = _loadYamlFile(pubspecPath);
    return yaml?['name'] as String?;
  }
}

/// Dash CLI configuration.
class DashConfig {
  const DashConfig({
    required this.databasePath,
    required this.schemasPath,
    required this.outputPath,
    required this.serverUrl,
    required this.serverPort,
    required this.basePath,
  });

  /// Default configuration.
  factory DashConfig.defaults() => const DashConfig(
    databasePath: 'storage/app.db',
    schemasPath: 'schemas/models',
    outputPath: 'lib',
    serverUrl: 'http://localhost',
    serverPort: 8080,
    basePath: '/admin',
  );

  /// Load configuration from YAML.
  factory DashConfig.fromYaml(YamlMap yaml) {
    final defaults = DashConfig.defaults();

    return DashConfig(
      databasePath: yaml['database']?['path'] as String? ?? defaults.databasePath,
      schemasPath: yaml['schemas']?['path'] as String? ?? defaults.schemasPath,
      outputPath: yaml['output']?['path'] as String? ?? defaults.outputPath,
      serverUrl: yaml['server']?['url'] as String? ?? defaults.serverUrl,
      serverPort: yaml['server']?['port'] as int? ?? defaults.serverPort,
      basePath: yaml['server']?['basePath'] as String? ?? defaults.basePath,
    );
  }

  /// Path to the database file.
  final String databasePath;

  /// Path to schema YAML files.
  final String schemasPath;

  /// Output path for generated code.
  final String outputPath;

  /// Server URL for API commands.
  final String serverUrl;

  /// Server port.
  final int serverPort;

  /// Admin panel base path.
  final String basePath;

  /// Get the full server URL.
  String get fullServerUrl => '$serverUrl:$serverPort$basePath';

  /// Get the API URL for CLI commands.
  String get apiUrl => '$serverUrl:$serverPort$basePath/_cli';
}
