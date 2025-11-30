import 'package:jaspr/jaspr.dart';

/// A reusable pagination component for displaying page navigation controls.
///
/// Renders previous/next buttons and page number links with ellipsis for large page counts.
/// Pages are shown with a sliding window around the current page.
class Pagination extends StatelessComponent {
  /// The current page number (1-indexed).
  final int currentPage;

  /// The total number of records.
  final int totalRecords;

  /// The number of records per page.
  final int perPage;

  /// A function that builds the URL for a given page number.
  final String Function(int page) buildPageUrl;

  const Pagination({
    required this.currentPage,
    required this.totalRecords,
    required this.perPage,
    required this.buildPageUrl,
    super.key,
  });

  /// Factory constructor for creating a Pagination component.
  static Pagination make({
    required int currentPage,
    required int totalRecords,
    required int perPage,
    required String Function(int page) buildPageUrl,
  }) {
    return Pagination(
      currentPage: currentPage,
      totalRecords: totalRecords,
      perPage: perPage,
      buildPageUrl: buildPageUrl,
    );
  }

  int get totalPages => (totalRecords / perPage).ceil();

  @override
  Component build(BuildContext context) {
    if (totalRecords == 0 || totalPages <= 1) {
      return div([]);
    }

    return div(classes: 'flex justify-between items-center px-6 py-4 border-t border-gray-700', [
      _buildPageInfo(),
      _buildPageControls(),
    ]);
  }

  Component _buildPageInfo() {
    return div(classes: 'text-sm text-gray-400', [text('Page $currentPage of $totalPages ($totalRecords total)')]);
  }

  Component _buildPageControls() {
    return div(classes: 'flex gap-2', [_buildPreviousButton(), ..._buildPageNumbers(), _buildNextButton()]);
  }

  Component _buildPreviousButton() {
    if (currentPage > 1) {
      return a(href: buildPageUrl(currentPage - 1), classes: _buttonClasses(), [text('← Previous')]);
    }
    return span(classes: _disabledButtonClasses(), [text('← Previous')]);
  }

  Component _buildNextButton() {
    if (currentPage < totalPages) {
      return a(href: buildPageUrl(currentPage + 1), classes: _buttonClasses(), [text('Next →')]);
    }
    return span(classes: _disabledButtonClasses(), [text('Next →')]);
  }

  List<Component> _buildPageNumbers() {
    final components = <Component>[];

    for (var i = 1; i <= totalPages; i++) {
      if (_shouldShowPage(i)) {
        components.add(_buildPageButton(i));
      } else if (i == currentPage - 2 || i == currentPage + 2) {
        components.add(_buildEllipsis());
      }
    }

    return components;
  }

  Component _buildPageButton(int page) {
    if (page == currentPage) {
      return span(classes: _activePageClasses(), [text('$page')]);
    }
    return a(href: buildPageUrl(page), classes: _buttonClasses(), [text('$page')]);
  }

  Component _buildEllipsis() {
    return span(classes: 'flex items-center px-2 text-gray-600', [text('...')]);
  }

  /// Determines if a page number should be shown.
  /// Shows first, last, and pages within 1 of the current page.
  bool _shouldShowPage(int page) {
    if (page == 1 || page == totalPages) return true;
    if (page >= currentPage - 1 && page <= currentPage + 1) return true;
    return false;
  }

  String _buttonClasses() {
    return 'inline-flex items-center justify-center gap-2 px-3 py-1.5 text-sm font-medium bg-gray-700 text-gray-300 hover:bg-gray-600 hover:text-gray-100 rounded-lg transition-all';
  }

  String _disabledButtonClasses() {
    return 'inline-flex items-center justify-center gap-2 px-3 py-1.5 text-sm font-medium bg-gray-700 text-gray-300 opacity-50 cursor-not-allowed rounded-lg';
  }

  String _activePageClasses() {
    return 'inline-flex items-center justify-center gap-2 px-3 py-1.5 text-sm font-semibold bg-gray-900 text-gray-100 rounded-lg border border-gray-700';
  }
}
