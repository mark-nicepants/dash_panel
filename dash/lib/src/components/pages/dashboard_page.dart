import 'package:jaspr/jaspr.dart';

/// Dashboard home page component.
class DashboardPage extends StatelessComponent {
  final String? resource;

  const DashboardPage({this.resource, super.key});

  @override
  Component build(BuildContext context) {
    final title = resource != null ? resource!.toUpperCase() : 'Dashboard';

    return div(classes: 'dashboard-content', [
      if (resource == null) ...[
        // Dashboard widgets
        div(classes: 'dashboard-widgets', [
          div(classes: 'widget-card', [
            h3([text('Welcome to DASH')]),
            p([text('Your modern admin panel for Dart applications.')]),
          ]),
          div(classes: 'widget-card', [
            h3([text('Quick Stats')]),
            ul([
              li([text('Total Users: 10')]),
              li([text('Total Posts: 25')]),
              li([text('Active Sessions: 3')]),
            ]),
          ]),
        ]),
      ] else ...[
        // Resource list view
        div(classes: 'resource-content', [
          div(classes: 'resource-header', [
            h2([text(title)]),
            button(classes: 'btn-primary', [text('+ New $resource')]),
          ]),
          div(classes: 'resource-table', [
            p([text('Resource table for $resource will be displayed here.')]),
          ]),
        ]),
      ],
    ]);
  }
}
