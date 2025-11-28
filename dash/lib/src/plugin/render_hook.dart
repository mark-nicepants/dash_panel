import 'package:jaspr/jaspr.dart';

/// Defines locations where plugins can inject content.
///
/// Render hooks allow plugins to add UI elements at specific points
/// in the layout without modifying core components.
///
/// Example:
/// ```dart
/// panel.renderHook(
///   RenderHook.sidebarFooter,
///   () => div([text('Plugin v1.0')]),
/// );
/// ```
enum RenderHook {
  // ============================================================
  // Document Hooks
  // ============================================================

  /// Start of the `<head>` element.
  headStart,

  /// End of the `<head>` element (before `</head>`).
  headEnd,

  /// Start of the `<body>` element.
  bodyStart,

  /// End of the `<body>` element (before `</body>`).
  bodyEnd,

  // ============================================================
  // Layout Hooks
  // ============================================================

  /// Start of the sidebar navigation (after dashboard link).
  sidebarNavStart,

  /// End of the sidebar navigation (after all resource links).
  sidebarNavEnd,

  /// Sidebar footer area (above logout button).
  sidebarFooter,

  // ============================================================
  // Content Hooks
  // ============================================================

  /// Before the main content area.
  contentBefore,

  /// After the main content area.
  contentAfter,

  // ============================================================
  // Resource Page Hooks
  // ============================================================

  /// Before the resource index table.
  resourceIndexBefore,

  /// After the resource index table.
  resourceIndexAfter,

  /// Before the resource form fields.
  resourceFormBefore,

  /// After the resource form fields.
  resourceFormAfter,

  /// Before the resource view content.
  resourceViewBefore,

  /// After the resource view content.
  resourceViewAfter,

  // ============================================================
  // Dashboard Hooks
  // ============================================================

  /// Start of the dashboard page.
  dashboardStart,

  /// End of the dashboard page.
  dashboardEnd,

  // ============================================================
  // Auth Hooks
  // ============================================================

  /// Before the login form.
  loginFormBefore,

  /// After the login form.
  loginFormAfter,
}

/// Type alias for render hook builder functions.
typedef RenderHookBuilder = Component Function();

/// Registry for managing render hooks.
///
/// Plugins register their hooks here, and components query
/// the registry to render hook content.
class RenderHookRegistry {
  final Map<RenderHook, List<RenderHookBuilder>> _hooks = {};

  /// Registers a builder function for a render hook.
  ///
  /// Multiple builders can be registered for the same hook.
  /// They will be rendered in the order they were registered.
  void register(RenderHook hook, RenderHookBuilder builder) {
    _hooks.putIfAbsent(hook, () => []).add(builder);
  }

  /// Checks if any builders are registered for a hook.
  bool hasHook(RenderHook hook) {
    return _hooks.containsKey(hook) && _hooks[hook]!.isNotEmpty;
  }

  /// Gets all builders registered for a hook.
  List<RenderHookBuilder> getBuilders(RenderHook hook) {
    return _hooks[hook] ?? [];
  }

  /// Renders all content for a hook as a list of components.
  ///
  /// Returns an empty list if no builders are registered.
  List<Component> render(RenderHook hook) {
    return getBuilders(hook).map((builder) => builder()).toList();
  }

  /// Renders all content for a hook wrapped in a container.
  ///
  /// Returns `null` if no builders are registered.
  Component? renderWrapped(RenderHook hook, {String? classes}) {
    final components = render(hook);
    if (components.isEmpty) return null;

    return div(classes: classes ?? '', components);
  }

  /// Clears all registered hooks.
  void clear() {
    _hooks.clear();
  }
}
