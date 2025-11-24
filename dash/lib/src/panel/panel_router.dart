import 'package:jaspr/server.dart';

import '../components/layout.dart';
import '../components/pages/dashboard_page.dart';
import '../components/pages/login_page.dart';
import '../components/styles.dart';
import 'panel_config.dart';

/// Handles routing and page rendering for the Dash panel.
///
/// Responsible for matching URL paths to appropriate pages
/// and rendering Jaspr components into HTML responses.
class PanelRouter {
  final PanelConfig _config;

  PanelRouter(this._config);

  /// Routes a request to the appropriate page handler.
  Future<Response> route(Request request) async {
    final path = request.url.path;
    final page = _getPageForPath(path);

    if (page == null) {
      return Response.notFound('Page not found');
    }

    return await _renderPage(page);
  }

  /// Determines which page component to render based on the path.
  Component? _getPageForPath(String path) {
    if (path.contains('login')) {
      return LoginPage(basePath: _config.path);
    }

    if (path.contains('resources/')) {
      final parts = path.split('/');
      final resourceIndex = parts.indexOf('resources');
      final resourceName = resourceIndex + 1 < parts.length ? parts[resourceIndex + 1] : '';

      return DashLayout(
        basePath: _config.path,
        resources: _config.resources,
        title: 'Resource: $resourceName',
        child: DashboardPage(resource: resourceName),
      );
    }

    // Default dashboard page
    return DashLayout(
      basePath: _config.path,
      resources: _config.resources,
      title: 'Dashboard',
      child: const DashboardPage(),
    );
  }

  /// Renders a Jaspr component into a complete HTML response.
  Future<Response> _renderPage(Component page) async {
    final rendered = await renderComponent(page);

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DASH Admin</title>
  <style>$dashStyles</style>
</head>
<body>
  ${rendered.body}
</body>
</html>
''';

    return Response.ok(
      html,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  }
}
