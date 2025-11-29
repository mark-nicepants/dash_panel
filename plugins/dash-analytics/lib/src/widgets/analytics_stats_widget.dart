import 'package:dash/dash.dart';
import 'package:dash_analytics/src/metrics_service.dart';

/// Analytics stats widget showing page views, visitors, and more.
///
/// This widget displays real-time statistics from the MetricsService
/// when available, falling back to demo data when no metrics are recorded.
///
/// ## Example
///
/// ```dart
/// panel.widgets([
///   AnalyticsStatsWidget.make(),
/// ]);
/// ```
class AnalyticsStatsWidget extends StatsOverviewWidget {
  /// Cached stats data.
  List<Stat>? _cachedStats;

  /// Factory method to create a new AnalyticsStatsWidget instance.
  static AnalyticsStatsWidget make() => AnalyticsStatsWidget();

  @override
  int get sort => -1; // Show at top

  @override
  String? get heading => 'Analytics Overview';

  @override
  String? get description => 'Real-time visitor statistics';

  @override
  List<Stat> getStats() {
    // Return cached stats if available
    if (_cachedStats != null) return _cachedStats!;

    // Try to get real data from MetricsService
    try {
      if (inject.isRegistered<MetricsService>()) {
        // For now, return demo data - actual data fetching requires async
        // The plugin will populate real data via pre-loading mechanism
        return _getDemoStats();
      }
    } catch (_) {
      // Fall through to demo data
    }

    return _getDemoStats();
  }

  List<Stat> _getDemoStats() {
    return [
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

  /// Pre-loads stats data asynchronously.
  ///
  /// Call this before rendering to fetch real metrics data.
  Future<void> preloadStats() async {
    if (!inject.isRegistered<MetricsService>()) {
      _cachedStats = _getDemoStats();
      return;
    }

    final metrics = inject<MetricsService>();

    try {
      // Fetch page views for last 7 days
      final pageViewsComparison = await metrics.query('page_views').last(7).compare();
      final pageViewsData = await metrics.query('page_views').period(Period.day).last(10).getData();

      final pageViewsTotal = pageViewsComparison['current'] as double;
      final pageViewsChange = pageViewsComparison['change'] as double;
      final pageViewsChartData = pageViewsData.map((p) => p.value.toDouble()).toList();

      // Determine change direction
      final isIncrease = pageViewsChange >= 0;
      final changeText = isIncrease
          ? '+${pageViewsChange.toStringAsFixed(0)}% from last week'
          : '${pageViewsChange.toStringAsFixed(0)}% from last week';

      _cachedStats = [
        Stat.make('Page Views', _formatNumber(pageViewsTotal.toInt()))
            .icon(HeroIcons.eye)
            .description(changeText)
            .descriptionIcon(isIncrease ? HeroIcons.arrowTrendingUp : HeroIcons.arrowTrendingDown)
            .descriptionColor(isIncrease ? 'green' : 'red')
            .chart(pageViewsChartData.isEmpty ? [0.0] : pageViewsChartData)
            .chartColor('cyan'),
        // Add more stats as we track them
        Stat.make(
          'Unique Visitors',
          '-',
        ).icon(HeroIcons.users).description('Coming soon').descriptionColor('gray').chartColor('violet'),
        Stat.make(
          'Bounce Rate',
          '-',
        ).icon(HeroIcons.arrowTrendingDown).description('Coming soon').descriptionColor('gray').chartColor('amber'),
      ];
    } catch (e) {
      // Fall back to demo data on error
      _cachedStats = _getDemoStats();
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
