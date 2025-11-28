import 'package:dash/dash.dart';
import 'package:jaspr/jaspr.dart';

/// Example analytics plugin that demonstrates Dash's plugin system.
///
/// This plugin shows how to:
/// - Register a plugin with a panel
/// - Add custom navigation items
/// - Inject content via render hooks
/// - Use fluent configuration
///
/// Usage:
/// ```dart
/// final panel = Panel()
///   ..plugins([
///     AnalyticsPlugin.make()
///       .trackingId('UA-12345678')
///       .enableDashboardWidget(true),
///   ]);
/// ```
class AnalyticsPlugin implements Plugin {
  String? _trackingId;
  bool _dashboardWidgetEnabled = false;
  bool _showSidebarBadge = true;

  /// Factory method to create a new AnalyticsPlugin instance.
  static AnalyticsPlugin make() => AnalyticsPlugin();

  // ============================================================
  // Configuration Methods (Fluent API)
  // ============================================================

  /// Sets the analytics tracking ID.
  AnalyticsPlugin trackingId(String id) {
    _trackingId = id;
    return this;
  }

  /// Enables or disables the dashboard widget.
  AnalyticsPlugin enableDashboardWidget([bool enabled = true]) {
    _dashboardWidgetEnabled = enabled;
    return this;
  }

  /// Shows or hides the sidebar badge.
  AnalyticsPlugin showSidebarBadge([bool show = true]) {
    _showSidebarBadge = show;
    return this;
  }

  // ============================================================
  // Configuration Getters
  // ============================================================

  /// Gets the configured tracking ID.
  String? get getTrackingId => _trackingId;

  /// Whether the dashboard widget is enabled.
  bool get hasDashboardWidget => _dashboardWidgetEnabled;

  /// Whether the sidebar badge is shown.
  bool get hasSidebarBadge => _showSidebarBadge;

  // ============================================================
  // Plugin Implementation
  // ============================================================

  @override
  String getId() => 'analytics';

  @override
  void register(Panel panel) {
    // Add a custom navigation item
    panel.navigationItems([
      NavigationItem.make('Analytics').url('/analytics').icon(HeroIcons.chartBar).group('Reports').sort(10),
    ]);

    // Add a render hook to show version in sidebar footer
    if (_showSidebarBadge) {
      panel.renderHook(
        RenderHook.sidebarFooter,
        () => div(classes: 'px-6 py-3 border-t border-gray-700', [
          div(classes: 'flex items-center gap-2 text-xs text-gray-500', [
            const Heroicon(HeroIcons.chartBar, size: 14),
            span([text('Analytics v1.0')]),
          ]),
        ]),
      );
    }

    // Add dashboard hook if enabled
    if (_dashboardWidgetEnabled) {
      panel.renderHook(RenderHook.dashboardStart, _buildAnalyticsWidget);
    }
  }

  @override
  void boot(Panel panel) {
    // Runtime initialization
    // This is where you would initialize analytics tracking, etc.
    if (_trackingId != null) {
      print('📊 Analytics plugin initialized with tracking ID: $_trackingId');
    }
  }

  /// Builds a simple analytics widget for the dashboard.
  Component _buildAnalyticsWidget() {
    return div(classes: 'bg-gray-800 rounded-lg p-6 mb-6', [
      h3(classes: 'text-lg font-semibold text-white mb-4', [text('Quick Stats')]),
      div(classes: 'grid grid-cols-3 gap-4', [
        _buildStatCard('Page Views', '12,345', HeroIcons.eye),
        _buildStatCard('Visitors', '1,234', HeroIcons.users),
        _buildStatCard('Bounce Rate', '32%', HeroIcons.arrowTrendingDown),
      ]),
    ]);
  }

  Component _buildStatCard(String label, String value, HeroIcons icon) {
    return div(classes: 'bg-gray-700 rounded-lg p-4', [
      div(classes: 'flex items-center gap-2 text-gray-400 mb-2', [
        Heroicon(icon, size: 16),
        span(classes: 'text-sm', [text(label)]),
      ]),
      div(classes: 'text-2xl font-bold text-white', [text(value)]),
    ]);
  }
}
