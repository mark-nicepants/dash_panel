import 'database_connector.dart';

/// Configuration for database connections.
///
/// Provides a fluent interface for configuring database connections
/// with different connectors.
class DatabaseConfig {
  final DatabaseConnector connector;
  final Map<String, dynamic> options;

  DatabaseConfig({
    required this.connector,
    this.options = const {},
  });

  /// Creates a configuration using the provided connector.
  factory DatabaseConfig.using(
    DatabaseConnector connector, {
    Map<String, dynamic>? options,
  }) {
    return DatabaseConfig(
      connector: connector,
      options: options ?? {},
    );
  }

  /// Establishes the database connection.
  Future<void> connect() => connector.connect();

  /// Closes the database connection.
  Future<void> close() => connector.close();
}
