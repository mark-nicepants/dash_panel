import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart' hide Middleware;

/// Abstract base class for all middleware in the Dash panel.
///
/// Middleware wraps HTTP handlers to add cross-cutting concerns like
/// authentication, logging, security headers, etc.
///
/// Implementations must provide a [call] method that takes an inner
/// handler and returns a new handler with the middleware applied.
abstract class Middleware {
  /// Wraps the given handler with this middleware.
  ///
  /// The returned handler should apply the middleware logic before
  /// calling the inner handler.
  Handler call(Handler innerHandler);

  /// Creates a [MiddlewareEntry] for this middleware.
  ///
  /// This is a convenience method for registering middleware in the stack.
  ///
  /// Example:
  /// ```dart
  /// stack.add(myMiddleware.toEntry());
  /// ```
  MiddlewareEntry toEntry();
}

/// Defines the high-level stages in the request pipeline.
///
/// Middleware is sorted first by stage (in enum order), then by priority
/// within each stage. This provides predictable ordering while allowing
/// fine-grained control for plugins.
///
/// **Stage Order:**
/// 1. [errorHandling] - Catch exceptions from all downstream middleware
/// 2. [security] - Add security headers (CORS, CSP, etc.)
/// 3. [logging] - Request logging
/// 4. [asset] - Serve static assets (before auth to avoid redirects)
/// 5. [cli] - Handle CLI API requests (before auth for CLI tool access)
/// 6. [auth] - Authentication and session management
/// 7. [application] - Application-level middleware (routing, custom handlers)
enum MiddlewareStage {
  /// Stage 0: Error handling wrapper.
  ///
  /// Catches unhandled exceptions from all downstream middleware.
  /// Typically only one middleware at this stage.
  errorHandling,

  /// Stage 1: Security headers.
  ///
  /// Adds OWASP recommended security headers (CSP, X-Frame-Options, etc.)
  /// to all responses.
  security,

  /// Stage 2: Request logging.
  ///
  /// Logs incoming requests and their responses.
  /// Runs before asset serving so all requests are logged.
  logging,

  /// Stage 3: Asset serving.
  ///
  /// Serves static assets (CSS, JS, images) and uploaded files.
  /// Runs before auth so assets don't require authentication.
  asset,

  /// Stage 4: CLI API handling.
  ///
  /// Handles CLI API requests (/_cli/*).
  /// Runs before auth so the CLI tool can access endpoints without login.
  cli,

  /// Stage 5: Authentication.
  ///
  /// Validates sessions, establishes [RequestContext] zone,
  /// and redirects unauthenticated users to login.
  ///
  /// **Note:** Plugin middleware at this stage runs outside the
  /// [RequestContext] zone. Use [application] stage to access
  /// [RequestContext.user] and [RequestContext.sessionId].
  auth,

  /// Stage 6: Application layer.
  ///
  /// Application-level middleware including custom handlers and routing.
  /// Runs inside the [RequestContext] zone established by auth.
  ///
  /// This is the recommended stage for plugin middleware that needs
  /// access to the authenticated user.
  application,
}

/// Represents a single middleware entry in the stack.
///
/// Each entry has a [stage] that determines its position in the pipeline,
/// and a [priority] for ordering within that stage.
///
/// **Priority Convention:**
/// - Default priority is 500
/// - Lower values run first within a stage
/// - Use < 500 to run before built-in middleware
/// - Use > 500 to run after built-in middleware
///
/// Example:
/// ```dart
/// // Rate limiting before auth
/// MiddlewareEntry.make(
///   id: 'rate-limiter',
///   stage: MiddlewareStage.auth,
///   priority: 100,  // Before default auth (500)
///   middleware: rateLimitMiddleware(),
/// )
/// ```
class MiddlewareEntry {
  /// Optional identifier for debugging and logging.
  final String? id;

  /// The stage this middleware belongs to.
  final MiddlewareStage stage;

  /// Priority within the stage. Lower values run first.
  ///
  /// Default is 500. Built-in middleware uses 400-600.
  final int priority;

  /// The Shelf middleware function.
  final Middleware middleware;

  /// The plugin that registered this middleware, if any.
  final String? pluginId;

  const MiddlewareEntry._({required this.stage, required this.middleware, this.id, this.priority = 500, this.pluginId});

  /// Creates a new middleware entry.
  ///
  /// Example:
  /// ```dart
  /// MiddlewareEntry.make(
  ///   id: 'cors-handler',
  ///   stage: MiddlewareStage.security,
  ///   priority: 100,
  ///   middleware: corsMiddleware(),
  /// )
  /// ```
  static MiddlewareEntry make({
    required MiddlewareStage stage,
    required Middleware middleware,
    String? id,
    int priority = 500,
    String? pluginId,
  }) {
    return MiddlewareEntry._(stage: stage, middleware: middleware, id: id, priority: priority, pluginId: pluginId);
  }

  /// Creates a middleware entry that runs before the default priority.
  ///
  /// Shorthand for setting priority to 100.
  static MiddlewareEntry before({
    required MiddlewareStage stage,
    required Middleware middleware,
    String? id,
    String? pluginId,
  }) {
    return MiddlewareEntry._(stage: stage, middleware: middleware, id: id, priority: 100, pluginId: pluginId);
  }

  /// Creates a middleware entry that runs after the default priority.
  ///
  /// Shorthand for setting priority to 900.
  static MiddlewareEntry after({
    required MiddlewareStage stage,
    required Middleware middleware,
    String? id,
    String? pluginId,
  }) {
    return MiddlewareEntry._(stage: stage, middleware: middleware, id: id, priority: 900, pluginId: pluginId);
  }

  @override
  String toString() {
    final idStr = id != null ? ' ($id)' : '';
    final pluginStr = pluginId != null ? ' [plugin: $pluginId]' : '';
    return 'MiddlewareEntry$idStr: ${stage.name} @ priority $priority$pluginStr';
  }
}

/// Manages the middleware pipeline for a Dash panel.
///
/// The stack collects middleware entries and builds them into a Shelf
/// handler chain. Middleware is sorted by stage (enum order) then by
/// priority within each stage.
///
/// Example usage:
/// ```dart
/// final stack = MiddlewareStack();
///
/// // Add built-in middleware
/// stack.add(MiddlewareEntry.make(
///   id: 'error-handler',
///   stage: MiddlewareStage.errorHandling,
///   middleware: errorHandlingMiddleware(),
/// ));
///
/// stack.add(MiddlewareEntry.make(
///   id: 'auth',
///   stage: MiddlewareStage.auth,
///   middleware: authMiddleware(authService),
/// ));
///
/// // Plugin adds rate limiting before auth
/// stack.add(MiddlewareEntry.before(
///   stage: MiddlewareStage.auth,
///   middleware: rateLimitMiddleware(),
///   pluginId: 'rate-limit',
/// ));
///
/// // Build the handler chain
/// final handler = stack.build(requestHandler);
/// ```
class MiddlewareStack {
  final List<MiddlewareEntry> _entries = [];

  /// Creates a new empty middleware stack.
  MiddlewareStack();

  /// Adds a middleware entry to the stack.
  void add(MiddlewareEntry entry) {
    _entries.add(entry);
  }

  /// Adds middleware at a specific stage with default priority.
  ///
  /// Convenience method equivalent to:
  /// ```dart
  /// add(MiddlewareEntry.make(
  ///   stage: stage,
  ///   middleware: middleware,
  ///   id: id,
  /// ));
  /// ```
  void addMiddleware(Middleware middleware) {
    add(middleware.toEntry());
  }

  /// Returns all registered middleware entries.
  ///
  /// Entries are not sorted; use [sortedEntries] for the final order.
  List<MiddlewareEntry> get entries => List.unmodifiable(_entries);

  /// Returns middleware entries sorted by stage and priority.
  ///
  /// This is the order in which middleware will be applied when
  /// [build] is called.
  List<MiddlewareEntry> get sortedEntries {
    final sorted = List<MiddlewareEntry>.from(_entries);
    sorted.sort((a, b) {
      // First compare by stage (enum index)
      final stageCompare = a.stage.index.compareTo(b.stage.index);
      if (stageCompare != 0) return stageCompare;

      // Then by priority within stage
      return a.priority.compareTo(b.priority);
    });
    return sorted;
  }

  /// Returns entries for a specific stage, sorted by priority.
  List<MiddlewareEntry> entriesForStage(MiddlewareStage stage) {
    return sortedEntries.where((e) => e.stage == stage).toList();
  }

  /// Builds the middleware pipeline around the given handler.
  ///
  /// Middleware is applied in order of stage (ascending enum index)
  /// and priority (ascending within stage). The first middleware in
  /// the sorted list wraps all subsequent middleware.
  ///
  /// Returns a [Handler] that processes requests through all middleware.
  Handler build(Handler innerHandler) {
    // Get sorted entries (stage order, then priority order)
    final sorted = sortedEntries;

    // Apply middleware in reverse order so first entry wraps the rest
    Handler handler = innerHandler;
    for (final entry in sorted.reversed) {
      handler = entry.middleware(handler);
    }

    return handler;
  }

  /// Returns the number of registered middleware entries.
  int get length => _entries.length;

  /// Whether the stack has any middleware entries.
  bool get isEmpty => _entries.isEmpty;

  /// Whether the stack has middleware entries.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Removes all middleware entries.
  void clear() {
    _entries.clear();
  }

  /// Returns a debug string showing all middleware in order.
  @visibleForTesting
  String debugString() {
    final buffer = StringBuffer('MiddlewareStack ($length entries):\n');
    for (final entry in sortedEntries) {
      buffer.writeln('  - $entry');
    }
    return buffer.toString();
  }
}
