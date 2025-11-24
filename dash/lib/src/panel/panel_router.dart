import 'package:jaspr/server.dart';

import '../components/layout.dart';
import '../components/pages/dashboard_page.dart';
import '../components/pages/login_page.dart';
import '../resources/resource_loader.dart';
import 'panel_config.dart';

/// Handles routing and page rendering for the Dash panel.
///
/// Responsible for matching URL paths to appropriate pages
/// and rendering Jaspr components into HTML responses.
class PanelRouter {
  final PanelConfig _config;
  final ResourceLoader _resourceLoader;

  PanelRouter(this._config, this._resourceLoader);

  /// Routes a request to the appropriate page handler.
  Future<Response> route(Request request) async {
    final path = request.url.path;
    final page = await _getPageForPath(path, request);
    return await _renderPage(page);
  }

  /// Determines which page component to render based on the path.
  Future<Component> _getPageForPath(String path, Request request) async {
    if (path.contains('login')) {
      return LoginPage(basePath: _config.path);
    }

    if (path.contains('resources/')) {
      final parts = path.split('/');
      final resourceIndex = parts.indexOf('resources');
      final resourceSlug = resourceIndex + 1 < parts.length ? parts[resourceIndex + 1] : '';

      // Find the matching resource by slug
      final resource = _config.resources.firstWhere(
        (r) => r.slug == resourceSlug,
        orElse: () => throw Exception('Resource not found: $resourceSlug'),
      );

      // Extract query parameters for filtering, sorting, pagination
      final queryParams = request.url.queryParameters;
      final searchQuery = queryParams['search'];
      final sortColumn = queryParams['sort'];
      final sortDirection = queryParams['direction'];
      final pageNum = int.tryParse(queryParams['page'] ?? '1') ?? 1;

      // Fetch records and total count
      final records = await resource.getRecords(
        searchQuery: searchQuery,
        sortColumn: sortColumn,
        sortDirection: sortDirection,
        page: pageNum,
      );
      final totalRecords = await resource.getRecordsCount(searchQuery: searchQuery);

      // Build the index page with current state
      final indexPage = resource.buildIndexPage(
        records: records,
        totalRecords: totalRecords,
        searchQuery: searchQuery,
        sortColumn: sortColumn,
        sortDirection: sortDirection,
        currentPage: pageNum,
      );
      return DashLayout(basePath: _config.path, resources: _config.resources, title: resource.label, child: indexPage);
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

    // Render the template with pre-loaded resources
    final html = _resourceLoader.renderTemplate(title: 'DASH Admin', body: rendered.body);

    return Response.ok(html, headers: {'content-type': 'text/html; charset=utf-8'});
  }
}
