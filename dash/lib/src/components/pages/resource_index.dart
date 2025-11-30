import 'dart:async';

import 'package:dash/src/actions/action.dart';
import 'package:dash/src/actions/prebuilt/delete_action.dart';
import 'package:dash/src/actions/prebuilt/edit_action.dart';
import 'package:dash/src/components/partials/breadcrumbs.dart';
import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/components/partials/page_header.dart';
import 'package:dash/src/components/partials/table/column_toggle.dart';
import 'package:dash/src/components/partials/table/table_components.dart';
import 'package:dash/src/interactive/interactive_component.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/resource.dart';
import 'package:dash/src/service_locator.dart';
import 'package:dash/src/table/table.dart';
import 'package:jaspr/jaspr.dart';

/// Resource index page for listing records.
/// Server-side renders the full page with search, sort, and pagination support.
class ResourceIndex<T extends Model> extends InteractiveComponent {
  // State properties
  String resourceSlug = '';
  String searchQuery = '';
  String sortColumn = '';
  String sortDirection = '';
  int currentPage = 1;

  // Data properties (not serialized)
  List<T> records = [];
  int totalRecords = 0;

  @override
  String get componentId => 'resource-index-$resourceSlug';

  @override
  String get componentName => 'resource-index-$resourceSlug';

  Resource<T> get resource => resourceFromSlug(resourceSlug) as Resource<T>;
  String get basePath => '${inject<PanelConfig>().path}/resources/${resource.slug}';
  Table<T> get tableConfig => resource.table(Table<T>());

  ResourceIndex({
    Resource<T>? resource,
    this.records = const [],
    this.totalRecords = 0,
    String? searchQuery,
    String? sortColumn,
    String? sortDirection,
    this.currentPage = 1,
  }) {
    if (resource != null) {
      resourceSlug = resource.slug;
    }
    this.searchQuery = searchQuery ?? '';
    this.sortColumn = sortColumn ?? '';
    this.sortDirection = sortDirection ?? '';
  }

  @override
  Map<String, dynamic> getState() => {
    'resourceSlug': resourceSlug,
    'searchQuery': searchQuery,
    'sortColumn': sortColumn,
    'sortDirection': sortDirection,
    'currentPage': currentPage,
  };

  @override
  void setState(Map<String, dynamic> state) {
    resourceSlug = state['resourceSlug'] ?? '';
    searchQuery = state['searchQuery'] ?? '';
    sortColumn = state['sortColumn'] ?? '';
    sortDirection = state['sortDirection'] ?? '';
    currentPage = state['currentPage'] ?? 1;
  }

  @override
  Map<String, Function(List<dynamic>)> getActions() => {
    'setPage': (args) {
      currentPage = args[0] as int;
      dispatch('update-url', {'url': _buildCurrentUrl()});
    },
    'sort': (args) {
      final col = args[0] as String;
      if (sortColumn == col) {
        sortDirection = sortDirection == 'asc' ? 'desc' : 'asc';
      } else {
        sortColumn = col;
        sortDirection = 'asc';
      }
      dispatch('update-url', {'url': _buildCurrentUrl()});
    },
  };

  @override
  Future<void> updated(String property) async {
    if (property == 'searchQuery') {
      currentPage = 1;
      dispatch('update-url', {'url': _buildCurrentUrl()});
    }
  }

  @override
  Future<void> beforeRender() async {
    records = await resource.getRecords(
      searchQuery: searchQuery,
      sortColumn: sortColumn,
      sortDirection: sortDirection,
      page: currentPage,
    );
    totalRecords = await resource.getRecordsCount(searchQuery: searchQuery);
  }

  String _buildCurrentUrl() {
    final params = <String>[
      if (sortColumn.isNotEmpty) 'sort=$sortColumn',
      if (sortDirection.isNotEmpty) 'direction=$sortDirection',
      if (searchQuery.isNotEmpty) 'search=$searchQuery',
      if (currentPage != 1) 'page=$currentPage',
    ];
    return params.isEmpty ? basePath : '$basePath?${params.join('&')}';
  }

  @override
  Component render() {
    return div(classes: 'flex flex-col gap-6', [_buildHeader(), _buildTableWithPagination()]);
  }

  /// Builds the table and pagination wrapped in a single container.
  Component _buildTableWithPagination() {
    return div(id: 'resource-table-wrapper', classes: 'flex flex-col gap-6', [_buildTableCard(), _buildPagination()]);
  }

  Component _buildHeader() {
    final headerActions = resource.indexHeaderActions();
    return PageHeader(
      title: resource.label,
      breadcrumbs: BreadCrumbs(
        items: [
          BreadCrumbItem(label: resource.label, url: basePath),
          const BreadCrumbItem(label: 'List'),
        ],
      ),
      actions: headerActions.map((action) => action.renderAsHeaderAction(basePath: basePath)).toList(),
    );
  }

  Component _buildTableCard() {
    final toggleableColumns = tableConfig.getColumns().where((c) => c.isToggleable()).toList();
    return div(classes: 'bg-gray-800 rounded-xl border border-gray-700', [
      div(classes: 'flex items-center justify-end gap-3 px-6 py-4 bg-gray-800 border-b border-gray-700 rounded-t-xl', [
        if (tableConfig.isSearchable()) _buildSearchBar(),
        if (toggleableColumns.isNotEmpty) ColumnToggle(columns: toggleableColumns, resourceSlug: resource.slug),
      ]),

      div(classes: 'overflow-hidden rounded-b-xl', [
        DataTable<T>(
          tableConfig: tableConfig,
          records: records,
          sortColumn: sortColumn,
          sortDirection: sortDirection,
          containerId: 'resource-table-container',
          resourceSlug: resource.slug,
          basePath: basePath,
          emptyStateIcon: resource.iconComponent,
          emptyStateHeading: 'No ${resource.label.toLowerCase()} found',
          emptyStateDescription: 'Get started by creating your first ${resource.singularLabel.toLowerCase()}.',
          rowActions: _buildRowActions,
        ),
      ]),
    ]);
  }

  Component _buildSearchBar() {
    return div(classes: 'relative', [
      div(classes: 'absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none', [
        const Heroicon(
          HeroIcons.magnifyingGlass,
          style: HeroIconStyle.solid,
          className: 'absolute left-2 top-2.5 h-4 w-4 text-gray-500',
        ),
      ]),
      input(
        type: InputType.text,
        classes:
            'block w-full pl-10 pr-3 py-2 border border-gray-600 rounded-lg leading-5 bg-gray-700 text-gray-300 placeholder-gray-400 focus:outline-none focus:bg-gray-900 focus:border-primary-500 focus:ring-primary-500 sm:text-sm transition duration-150 ease-in-out',
        attributes: {'placeholder': tableConfig.getSearchPlaceholder(), 'wire:model.debounce.300ms': 'searchQuery'},
        value: searchQuery,
      ),
    ]);
  }

  List<Component> _buildRowActions(T record) {
    // Use actions from table config, or default to Edit + Delete
    final actions = tableConfig.hasActions()
        ? tableConfig.getActions()
        : <Action<T>>[EditAction.make<T>(), DeleteAction.make<T>(resource.singularLabel.toLowerCase())];

    return actions
        .where((action) => action.isVisible(record))
        .map((action) => action.render(record, basePath: basePath))
        .toList();
  }

  Component _buildPagination() {
    if (!tableConfig.isPaginated()) return div([]);

    final totalPages = (totalRecords / tableConfig.getRecordsPerPage()).ceil();
    if (totalPages <= 1) return div([]);

    return div(classes: 'flex items-center justify-between px-4 py-3 bg-gray-800 border-t border-gray-700 sm:px-6', [
      div(classes: 'flex justify-between flex-1 sm:hidden', [
        if (currentPage > 1)
          button(
            classes:
                'relative inline-flex items-center px-4 py-2 text-sm font-medium text-gray-300 bg-gray-700 border border-gray-600 rounded-md hover:bg-gray-600',
            attributes: {'wire:click': 'setPage(${currentPage - 1})'},
            [text('Previous')],
          )
        else
          div([]),
        if (currentPage < totalPages)
          button(
            classes:
                'relative inline-flex items-center px-4 py-2 ml-3 text-sm font-medium text-gray-300 bg-gray-700 border border-gray-600 rounded-md hover:bg-gray-600',
            attributes: {'wire:click': 'setPage(${currentPage + 1})'},
            [text('Next')],
          )
        else
          div([]),
      ]),
      div(classes: 'hidden sm:flex sm:flex-1 sm:items-center sm:justify-between', [
        div([
          p(classes: 'text-sm text-gray-400', [
            text('Showing '),
            span(classes: 'font-medium', [text('${(currentPage - 1) * tableConfig.getRecordsPerPage() + 1}')]),
            text(' to '),
            span(classes: 'font-medium', [
              text('${(currentPage * tableConfig.getRecordsPerPage()).clamp(0, totalRecords)}'),
            ]),
            text(' of '),
            span(classes: 'font-medium', [text('$totalRecords')]),
            text(' results'),
          ]),
        ]),
        div([
          nav(classes: 'relative z-0 inline-flex -space-x-px rounded-md shadow-sm', [
            // Previous
            button(
              classes:
                  'relative inline-flex items-center px-2 py-2 text-sm font-medium text-gray-400 bg-gray-800 border border-gray-600 rounded-l-md hover:bg-gray-700 ${currentPage == 1 ? 'opacity-50 cursor-not-allowed' : ''}',
              attributes: currentPage > 1 ? {'wire:click': 'setPage(${currentPage - 1})'} : {'disabled': 'disabled'},
              [
                span(classes: 'sr-only', [text('Previous')]),
                const Heroicon(HeroIcons.chevronLeft, className: 'w-5 h-5'),
              ],
            ),
            // Pages (simplified)
            for (var i = 1; i <= totalPages; i++)
              if (i == 1 || i == totalPages || (i >= currentPage - 1 && i <= currentPage + 1))
                button(
                  classes: i == currentPage
                      ? 'relative z-10 inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-primary-600 border border-primary-500'
                      : 'relative inline-flex items-center px-4 py-2 text-sm font-medium text-gray-300 bg-gray-800 border border-gray-600 hover:bg-gray-700',
                  attributes: {'wire:click': 'setPage($i)'},
                  [text('$i')],
                )
              else if (i == currentPage - 2 || i == currentPage + 2)
                span(
                  classes:
                      'relative inline-flex items-center px-4 py-2 text-sm font-medium text-gray-400 bg-gray-800 border border-gray-600',
                  [text('...')],
                ),
            // Next
            button(
              classes:
                  'relative inline-flex items-center px-2 py-2 text-sm font-medium text-gray-400 bg-gray-800 border border-gray-600 rounded-r-md hover:bg-gray-700 ${currentPage == totalPages ? 'opacity-50 cursor-not-allowed' : ''}',
              attributes: currentPage < totalPages
                  ? {'wire:click': 'setPage(${currentPage + 1})'}
                  : {'disabled': 'disabled'},
              [
                span(classes: 'sr-only', [text('Next')]),
                const Heroicon(HeroIcons.chevronRight, className: 'w-5 h-5'),
              ],
            ),
          ]),
        ]),
      ]),
    ]);
  }
}
