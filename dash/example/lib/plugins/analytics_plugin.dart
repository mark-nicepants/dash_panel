import 'package:dash/dash.dart';
import 'package:jaspr/jaspr.dart';

/// Example analytics plugin that demonstrates Dash's plugin system.
///
/// This plugin shows how to:
/// - Register a plugin with a panel
/// - Add custom navigation items
/// - Register dashboard widgets
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

    // Register dashboard widgets if enabled
    if (_dashboardWidgetEnabled) {
      panel.widgets([AnalyticsStatsWidget.make(), PageViewsChartWidget.make(), TrafficSourcesChartWidget.make()]);
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
}

/// Analytics stats widget showing page views, visitors, and bounce rate.
///
/// This widget extends [StatsOverviewWidget] to display multiple stat cards
/// with sparkline charts.
class AnalyticsStatsWidget extends StatsOverviewWidget {
  /// Factory method to create a new AnalyticsStatsWidget instance.
  static AnalyticsStatsWidget make() => AnalyticsStatsWidget();

  @override
  int get sort => -1; // Show at top

  @override
  String? get heading => 'Analytics Overview';

  @override
  String? get description => 'Real-time visitor statistics';

  @override
  List<Stat> getStats() => [
    Stat.make('Page Views', '12,345')
        .icon(HeroIcons.eye)
        .description('+23% from last week')
        .descriptionIcon(HeroIcons.arrowTrendingUp)
        .descriptionColor('green')
        .chart([45, 52, 38, 65, 72, 58, 90, 85, 95, 102])
        .chartColor('cyan'),
    Stat.make('Unique Visitors', '1,234')
        .icon(HeroIcons.users)
        .description('+12% from last week')
        .descriptionIcon(HeroIcons.arrowTrendingUp)
        .descriptionColor('green')
        .chart([120, 150, 180, 165, 200, 220, 195, 240, 280, 310])
        .chartColor('violet'),
    Stat.make('Bounce Rate', '32%')
        .icon(HeroIcons.arrowTrendingDown)
        .description('-5% from last week')
        .descriptionIcon(HeroIcons.arrowTrendingDown)
        .descriptionColor('green')
        .chart([42, 38, 45, 35, 38, 32, 35, 30, 32, 28])
        .chartColor('amber'),
  ];
}

/// Page views line chart widget showing weekly traffic trends.
class PageViewsChartWidget extends LineChartWidget {
  /// Factory method to create a new PageViewsChartWidget instance.
  static PageViewsChartWidget make() => PageViewsChartWidget();

  @override
  int get sort => 10;

  @override
  int get columnSpan => 8;

  @override
  String? get heading => 'Page Views';

  @override
  String? get description => 'Weekly page view trends';

  @override
  ChartData getData() => const ChartData(
    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    datasets: [
      ChartDataset(
        label: 'This Week',
        data: [1200, 1900, 3000, 5000, 4200, 3500, 2100],
        borderColor: 'rgb(6, 182, 212)',
        backgroundColor: 'rgba(6, 182, 212, 0.1)',
        tension: 0.3,
        fill: true,
      ),
      ChartDataset(
        label: 'Last Week',
        data: [800, 1200, 2200, 3800, 3200, 2800, 1800],
        borderColor: 'rgb(156, 163, 175)',
        backgroundColor: 'rgba(156, 163, 175, 0.05)',
        tension: 0.3,
        fill: true,
      ),
    ],
  );
}

/// Traffic sources doughnut chart widget.
class TrafficSourcesChartWidget extends DoughnutChartWidget {
  /// Factory method to create a new TrafficSourcesChartWidget instance.
  static TrafficSourcesChartWidget make() => TrafficSourcesChartWidget();

  @override
  int get sort => 20;

  @override
  int get columnSpan => 4;

  @override
  String? get heading => 'Traffic Sources';

  @override
  String? get description => 'Where visitors come from';

  @override
  ChartData getData() => const ChartData(
    labels: ['Direct', 'Organic', 'Referral', 'Social', 'Email'],
    datasets: [
      ChartDataset(
        label: 'Traffic Sources',
        data: [35, 30, 18, 12, 5],
        backgroundColor: [
          'rgb(6, 182, 212)', // Cyan
          'rgb(139, 92, 246)', // Violet
          'rgb(245, 158, 11)', // Amber
          'rgb(34, 197, 94)', // Green
          'rgb(239, 68, 68)', // Red
        ],
        borderColor: [
          'rgb(6, 182, 212)',
          'rgb(139, 92, 246)',
          'rgb(245, 158, 11)',
          'rgb(34, 197, 94)',
          'rgb(239, 68, 68)',
        ],
        borderWidth: 2,
      ),
    ],
  );
}
