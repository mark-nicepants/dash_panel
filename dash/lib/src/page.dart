/// Base class for custom pages in Dash.
///
/// A [Page] represents a standalone page in your admin panel that is not
/// tied to a specific resource.
///
/// Example:
/// ```dart
/// class DashboardPage extends Page {
///   @override
///   String get title => 'Dashboard';
///
///   @override
///   String get route => '/';
/// }
/// ```
abstract class Page {
  /// The title of this page.
  String get title;

  /// The route path for this page.
  String get route;

  /// The icon to display for this page in navigation.
  String? get icon => null;

  /// The navigation group this page belongs to.
  String? get navigationGroup => null;

  /// The sort order for this page in navigation.
  int get navigationSort => 0;

  /// Whether this page should be shown in navigation.
  bool get shouldRegisterNavigation => true;
}
