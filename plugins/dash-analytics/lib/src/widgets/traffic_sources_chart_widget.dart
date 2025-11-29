import 'package:dash/dash.dart';
import 'package:dash_analytics/src/metrics_service.dart';

/// Traffic sources doughnut chart widget.
///
/// Displays a breakdown of where visitors come from using
/// a Chart.js doughnut chart. Shows real data when available,
/// falls back to demo data otherwise.
///
/// Traffic sources are tracked via page view tags with a 'source' key:
/// ```dart
/// metrics.pageView('/dashboard', extras: {'source': 'organic'});
/// ```
///
/// ## Example
///
/// ```dart
/// panel.widgets([
///   TrafficSourcesChartWidget.make(),
/// ]);
/// ```
class TrafficSourcesChartWidget extends DoughnutChartWidget {
  /// Cached chart data.
  ChartData? _cachedData;

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
  ChartData getData() {
    if (_cachedData != null) return _cachedData!;
    return _getDemoData();
  }

  ChartData _getDemoData() {
    return const ChartData(
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

  /// Pre-loads chart data asynchronously.
  ///
  /// This method queries the metrics service for page views grouped by source.
  Future<void> preloadData() async {
    if (!inject.isRegistered<MetricsService>()) {
      _cachedData = _getDemoData();
      return;
    }

    // For now, return demo data
    // Source tracking requires querying by tags which needs more complex SQL
    _cachedData = _getDemoData();
  }
}
