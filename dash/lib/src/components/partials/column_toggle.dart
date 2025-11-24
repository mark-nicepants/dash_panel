import 'dart:convert';

import 'package:jaspr/jaspr.dart';

import '../../table/columns/column.dart';

/// Column visibility toggle component with Alpine.js-powered interactivity.
class ColumnToggle extends StatelessComponent {
  final List<TableColumn> columns;
  final String resourceSlug;

  const ColumnToggle({required this.columns, required this.resourceSlug, super.key});

  @override
  Component build(BuildContext context) {
    final defaults = {for (final column in columns) column.getName(): !column.isToggledHiddenByDefault()};
    final encodedDefaults = jsonEncode(defaults);

    return div(
      classes: 'column-toggle',
      attributes: {'x-data': "columnVisibility('$resourceSlug', $encodedDefaults)", 'x-cloak': ''},
      [
        button(
          type: ButtonType.button,
          classes: 'btn btn-secondary column-toggle-button',
          attributes: {'x-on:click': 'open = !open', 'x-bind:aria-expanded': 'open', 'aria-haspopup': 'true'},
          [
            span(classes: 'btn-icon', [text('☰')]),
            span([text('Columns')]),
          ],
        ),
        div(
          classes: 'column-toggle-menu',
          attributes: {'x-show': 'open', 'x-transition.opacity': '', '@click.outside': 'open = false'},
          [
            div(classes: 'column-toggle-header', [text('Toggle columns')]),
            ul(classes: 'column-toggle-options', [
              for (final column in columns)
                li([
                  button(
                    type: ButtonType.button,
                    classes: 'column-toggle-option',
                    attributes: {
                      'x-on:click': "toggle('${column.getName()}')",
                      'x-bind:class': "{'active': isVisible('${column.getName()}')}",
                    },
                    [
                      span(
                        classes: 'column-toggle-check',
                        attributes: {'x-show': "isVisible('${column.getName()}')"},
                        [text('✓')],
                      ),
                      span(classes: 'column-toggle-label', [text(column.getLabel())]),
                    ],
                  ),
                ]),
            ]),
            div(classes: 'column-toggle-footer', [
              button(
                type: ButtonType.button,
                classes: 'btn btn-secondary',
                attributes: {'x-on:click': 'showAll()'},
                [text('Show all')],
              ),
              button(
                type: ButtonType.button,
                classes: 'btn btn-secondary',
                attributes: {'x-on:click': 'hideAll()'},
                [text('Hide all')],
              ),
              button(
                type: ButtonType.button,
                classes: 'btn btn-secondary',
                attributes: {'x-on:click': 'reset()'},
                [text('Reset')],
              ),
            ]),
          ],
        ),
      ],
    );
  }
}
