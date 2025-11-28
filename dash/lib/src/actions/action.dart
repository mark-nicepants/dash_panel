import 'package:dash/src/actions/action_color.dart';
import 'package:dash/src/actions/action_size.dart';
import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/table/columns/text_column.dart' show IconPosition;
import 'package:jaspr/jaspr.dart';

/// Base class for all Dash actions.
///
/// An [Action] represents an interactive button that can perform operations
/// like navigating to URLs, executing callbacks, or showing confirmations.
///
/// Actions use a fluent builder API for configuration:
///
/// ```dart
/// Action.make('edit')
///   .label('Edit User')
///   .icon(HeroIcons.pencilSquare)
///   .color(ActionColor.primary)
///   .url((record) => '/users/${record.id}/edit')
/// ```
///
/// Actions can also execute server-side code:
///
/// ```dart
/// Action.make('delete')
///   .label('Delete')
///   .color(ActionColor.danger)
///   .requiresConfirmation()
///   .action((record) async => await record.delete())
/// ```
class Action<T extends Model> {
  final String _name;

  // Label
  String? _label;
  bool _isLabelHidden = false;

  // Icon
  HeroIcons? _icon;
  IconPosition _iconPosition = IconPosition.before;

  // Color & Size
  ActionColor _color = ActionColor.primary;
  ActionSize _size = ActionSize.sm;

  // Visibility & State
  bool Function(T record)? _hiddenWhen;
  bool Function(T record)? _visibleWhen;
  bool Function(T record)? _disabledWhen;

  // URL Navigation
  String Function(T record, String basePath)? _url;
  bool _openUrlInNewTab = false;

  // Confirmation
  bool _requiresConfirmation = false;
  String? _confirmationHeading;
  String? _confirmationDescription;
  String? _confirmationButtonLabel;
  String? _cancelButtonLabel;

  // Action Callback (for POST actions)
  String Function(T record, String basePath)? _actionUrl;
  String _actionMethod = 'POST';

  // Tooltip
  String? _tooltip;

  // Extra attributes
  Map<String, String>? _extraAttributes;

  /// Creates a new action with the given [name].
  ///
  /// The name is used as a unique identifier and defaults to the label
  /// if not explicitly set.
  Action(this._name);

  /// Factory method to create a new action.
  ///
  /// This is the preferred way to create actions:
  /// ```dart
  /// Action.make('edit').label('Edit').icon(HeroIcons.pencil)
  /// ```
  static Action<T> make<T extends Model>(String name) => Action<T>(name);

  // ============================================================
  // Label Configuration
  // ============================================================

  /// Sets the display label for the action.
  ///
  /// If not set, the label is derived from the action name.
  Action<T> label(String label) {
    _label = label;
    return this;
  }

  /// Hides the label, showing only the icon.
  Action<T> hiddenLabel([bool condition = true]) {
    _isLabelHidden = condition;
    return this;
  }

  // ============================================================
  // Icon Configuration
  // ============================================================

  /// Sets the icon for the action.
  Action<T> icon(HeroIcons icon) {
    _icon = icon;
    return this;
  }

  /// Sets the icon position relative to the label.
  Action<T> iconPosition(IconPosition position) {
    _iconPosition = position;
    return this;
  }

  // ============================================================
  // Color & Size Configuration
  // ============================================================

  /// Sets the color variant for the action.
  Action<T> color(ActionColor color) {
    _color = color;
    return this;
  }

  /// Sets the size of the action button.
  Action<T> size(ActionSize size) {
    _size = size;
    return this;
  }

  // ============================================================
  // Visibility & State
  // ============================================================

  /// Conditionally hides the action based on the record.
  ///
  /// ```dart
  /// Action.make('restore')
  ///   .hidden((record) => record.deletedAt == null)
  /// ```
  Action<T> hidden(bool Function(T record) condition) {
    _hiddenWhen = condition;
    return this;
  }

  /// Conditionally shows the action based on the record.
  ///
  /// ```dart
  /// Action.make('restore')
  ///   .visible((record) => record.deletedAt != null)
  /// ```
  Action<T> visible(bool Function(T record) condition) {
    _visibleWhen = condition;
    return this;
  }

  /// Conditionally disables the action based on the record.
  ///
  /// ```dart
  /// Action.make('edit')
  ///   .disabled((record) => record.isLocked)
  /// ```
  Action<T> disabled(bool Function(T record) condition) {
    _disabledWhen = condition;
    return this;
  }

  // ============================================================
  // URL Navigation
  // ============================================================

  /// Sets a URL to navigate to when the action is triggered.
  ///
  /// ```dart
  /// Action.make('edit')
  ///   .url((record, basePath) => '$basePath/${record.id}/edit')
  /// ```
  Action<T> url(String Function(T record, String basePath) url) {
    _url = url;
    return this;
  }

  /// Opens the URL in a new tab.
  Action<T> openUrlInNewTab([bool condition = true]) {
    _openUrlInNewTab = condition;
    return this;
  }

  // ============================================================
  // Confirmation
  // ============================================================

  /// Requires confirmation before executing the action.
  ///
  /// Shows a browser confirmation dialog by default.
  Action<T> requiresConfirmation([bool condition = true]) {
    _requiresConfirmation = condition;
    return this;
  }

  /// Sets the heading for the confirmation dialog.
  Action<T> confirmationHeading(String heading) {
    _confirmationHeading = heading;
    return this;
  }

  /// Sets the description for the confirmation dialog.
  Action<T> confirmationDescription(String description) {
    _confirmationDescription = description;
    return this;
  }

  /// Sets the label for the confirmation button.
  Action<T> confirmationButtonLabel(String label) {
    _confirmationButtonLabel = label;
    return this;
  }

  /// Sets the label for the cancel button.
  Action<T> cancelButtonLabel(String label) {
    _cancelButtonLabel = label;
    return this;
  }

  // ============================================================
  // Action Callback (POST actions)
  // ============================================================

  /// Sets the URL to POST to when the action is triggered.
  ///
  /// ```dart
  /// Action.make('delete')
  ///   .actionUrl((record, basePath) => '$basePath/${record.id}/delete')
  ///   .requiresConfirmation()
  /// ```
  Action<T> actionUrl(String Function(T record, String basePath) url) {
    _actionUrl = url;
    return this;
  }

  /// Sets the HTTP method for the action (default: POST).
  Action<T> method(String method) {
    _actionMethod = method.toUpperCase();
    return this;
  }

  // ============================================================
  // Tooltip & Extra Attributes
  // ============================================================

  /// Sets a tooltip to show on hover.
  Action<T> tooltip(String tooltip) {
    _tooltip = tooltip;
    return this;
  }

  /// Sets extra HTML attributes for the action element.
  Action<T> extraAttributes(Map<String, String> attributes) {
    _extraAttributes = attributes;
    return this;
  }

  // ============================================================
  // Getters
  // ============================================================

  /// Gets the action name.
  String getName() => _name;

  /// Gets the display label, derived from name if not set.
  String getLabel() {
    if (_label != null) return _label!;
    // Convert name to title case: 'editUser' -> 'Edit User'
    return _name
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .replaceAll(RegExp(r'[-_]'), ' ')
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  /// Gets whether the label is hidden.
  bool isLabelHidden() => _isLabelHidden;

  /// Gets the icon.
  HeroIcons? getIcon() => _icon;

  /// Gets the icon position.
  IconPosition getIconPosition() => _iconPosition;

  /// Gets the color.
  ActionColor getColor() => _color;

  /// Gets the size.
  ActionSize getSize() => _size;

  /// Checks if the action is hidden for the given record.
  bool isHidden(T record) {
    if (_hiddenWhen != null && _hiddenWhen!(record)) return true;
    if (_visibleWhen != null && !_visibleWhen!(record)) return true;
    return false;
  }

  /// Checks if the action is visible for the given record.
  bool isVisible(T record) => !isHidden(record);

  /// Checks if the action is disabled for the given record.
  bool isDisabled(T record) => _disabledWhen?.call(record) ?? false;

  /// Gets the URL for the given record, if set.
  String? getUrl(T record, String basePath) => _url?.call(record, basePath);

  /// Gets whether to open URL in new tab.
  bool shouldOpenUrlInNewTab() => _openUrlInNewTab;

  /// Gets whether confirmation is required.
  bool isConfirmationRequired() => _requiresConfirmation;

  /// Gets the confirmation heading.
  String getConfirmationHeading() => _confirmationHeading ?? 'Are you sure?';

  /// Gets the confirmation description.
  String? getConfirmationDescription() => _confirmationDescription;

  /// Gets the confirmation button label.
  String getConfirmationButtonLabel() => _confirmationButtonLabel ?? 'Confirm';

  /// Gets the cancel button label.
  String getCancelButtonLabel() => _cancelButtonLabel ?? 'Cancel';

  /// Gets the action URL for POST requests.
  String? getActionUrl(T record, String basePath) => _actionUrl?.call(record, basePath);

  /// Gets the HTTP method.
  String getMethod() => _actionMethod;

  /// Gets the tooltip.
  String? getTooltip() => _tooltip;

  /// Gets extra attributes.
  Map<String, String>? getExtraAttributes() => _extraAttributes;

  /// Checks if this is a URL action (navigation).
  bool isUrlAction() => _url != null;

  /// Checks if this is a POST action.
  bool isPostAction() => _actionUrl != null;

  // ============================================================
  // Rendering
  // ============================================================

  /// Renders the action as a Jaspr [Component].
  ///
  /// The action is rendered differently based on its configuration:
  /// - URL actions render as `<a>` tags
  /// - POST actions render as `<form>` with `<button>`
  Component render(T record, {required String basePath}) {
    if (isHidden(record)) {
      return span([]); // Return empty component
    }

    final isDisabledState = isDisabled(record);

    // Build content (icon + label)
    final content = _buildContent();

    // Get CSS classes
    final classes = _buildClasses(isDisabledState);

    // URL action - render as <a> tag
    if (isUrlAction()) {
      final url = getUrl(record, basePath)!;
      final attrs = <String, String>{
        if (_openUrlInNewTab) 'target': '_blank',
        if (_tooltip != null) 'title': _tooltip!,
        ..._extraAttributes ?? {},
      };

      if (isDisabledState) {
        return span(classes: '$classes opacity-50 cursor-not-allowed', content);
      }

      return a(href: url, classes: classes, attributes: attrs, content);
    }

    // POST action - render as <form> with <button>
    if (isPostAction()) {
      final url = getActionUrl(record, basePath)!;
      final confirmScript = _requiresConfirmation ? "return confirm('${_getConfirmationMessage()}')" : null;

      return form(action: url, method: FormMethod.post, classes: 'inline', [
        // Method spoofing for DELETE/PUT/PATCH
        if (_actionMethod != 'POST') input(type: InputType.hidden, name: '_method', value: _actionMethod),
        button(
          type: ButtonType.submit,
          classes: classes,
          attributes: {
            if (confirmScript != null) 'onclick': confirmScript,
            if (_tooltip != null) 'title': _tooltip!,
            if (isDisabledState) 'disabled': 'true',
            ..._extraAttributes ?? {},
          },
          content,
        ),
      ]);
    }

    // Fallback - render as disabled button
    return button(
      type: ButtonType.button,
      classes: '$classes opacity-50 cursor-not-allowed',
      attributes: {'disabled': 'true'},
      content,
    );
  }

  /// Builds the content (icon + label) for the action.
  List<Component> _buildContent() {
    final components = <Component>[];

    if (_icon != null && _iconPosition == IconPosition.before) {
      components.add(Heroicon(_icon!, size: _getIconSize()));
    }

    if (!_isLabelHidden) {
      components.add(text(getLabel()));
    }

    if (_icon != null && _iconPosition == IconPosition.after) {
      components.add(Heroicon(_icon!, size: _getIconSize()));
    }

    return components;
  }

  /// Gets the icon size based on action size.
  int _getIconSize() => switch (_size) {
    ActionSize.xs => 14,
    ActionSize.sm => 16,
    ActionSize.md => 18,
    ActionSize.lg => 20,
  };

  /// Builds CSS classes for the action button.
  String _buildClasses(bool isDisabled) {
    final baseClasses = 'inline-flex items-center gap-1.5 font-medium rounded-md transition-colors';

    final sizeClasses = switch (_size) {
      ActionSize.xs => 'px-2 py-1 text-xs',
      ActionSize.sm => 'px-3 py-1.5 text-xs',
      ActionSize.md => 'px-4 py-2 text-sm',
      ActionSize.lg => 'px-5 py-2.5 text-base',
    };

    final colorClasses = switch (_color) {
      ActionColor.primary => 'text-lime-400 hover:text-lime-300 bg-gray-700 hover:bg-gray-600',
      ActionColor.secondary => 'text-gray-300 hover:text-white bg-gray-700 hover:bg-gray-600',
      ActionColor.danger => 'text-red-400 hover:text-white bg-gray-700 hover:bg-red-600',
      ActionColor.warning => 'text-amber-400 hover:text-amber-300 bg-gray-700 hover:bg-gray-600',
      ActionColor.success => 'text-green-400 hover:text-green-300 bg-gray-700 hover:bg-gray-600',
      ActionColor.info => 'text-blue-400 hover:text-blue-300 bg-gray-700 hover:bg-gray-600',
    };

    return '$baseClasses $sizeClasses $colorClasses';
  }

  /// Gets the confirmation message for the dialog.
  String _getConfirmationMessage() {
    if (_confirmationDescription != null) {
      return '$_confirmationHeading\\n\\n$_confirmationDescription';
    }
    return _confirmationHeading ?? 'Are you sure?';
  }

  // ============================================================
  // Header Action Rendering
  // ============================================================

  /// Renders the action as a header button (without record context).
  ///
  /// Header actions are used in page headers and don't operate on a specific
  /// record. They typically navigate to URLs like create pages.
  Component renderAsHeaderAction({required String basePath}) {
    final content = _buildHeaderContent();
    final classes = _buildHeaderClasses();

    // For header actions, we expect a URL that doesn't need a record
    if (_url != null) {
      // Create a dummy call - the URL function should handle null-like behavior
      // For header actions, the basePath is what matters
      final attrs = <String, String>{
        if (_openUrlInNewTab) 'target': '_blank',
        if (_tooltip != null) 'title': _tooltip!,
        ..._extraAttributes ?? {},
      };

      return a(href: '$basePath/create', classes: classes, attributes: attrs, content);
    }

    // Fallback - render as a button (for POST actions in headers)
    return button(
      type: ButtonType.button,
      classes: classes,
      attributes: {if (_tooltip != null) 'title': _tooltip!, ..._extraAttributes ?? {}},
      content,
    );
  }

  /// Builds content for header actions (larger icon size).
  List<Component> _buildHeaderContent() {
    final components = <Component>[];

    if (_icon != null && _iconPosition == IconPosition.before) {
      components.add(Heroicon(_icon!, size: 18));
    }

    if (!_isLabelHidden) {
      components.add(text(getLabel()));
    }

    if (_icon != null && _iconPosition == IconPosition.after) {
      components.add(Heroicon(_icon!, size: 18));
    }

    return components;
  }

  /// Builds CSS classes for header action buttons (more prominent styling).
  String _buildHeaderClasses() {
    final baseClasses = 'inline-flex items-center gap-2 font-semibold rounded-lg transition-all duration-200';

    final sizeClasses = switch (_size) {
      ActionSize.xs => 'text-xs px-3 py-1.5',
      ActionSize.sm => 'text-sm px-3 py-1.5',
      ActionSize.md => 'text-sm px-4 py-2',
      ActionSize.lg => 'text-base px-6 py-3',
    };

    final colorClasses = switch (_color) {
      ActionColor.primary =>
        'bg-lime-500 text-white hover:bg-lime-600 active:bg-lime-700 focus:ring-2 focus:ring-lime-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ActionColor.secondary =>
        'bg-gray-700 text-gray-300 hover:bg-gray-600 hover:text-gray-100 active:bg-gray-800 focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ActionColor.danger =>
        'bg-red-600 text-white hover:bg-red-700 active:bg-red-800 focus:ring-2 focus:ring-red-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ActionColor.warning =>
        'bg-amber-500 text-white hover:bg-amber-600 active:bg-amber-700 focus:ring-2 focus:ring-amber-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ActionColor.success =>
        'bg-green-600 text-white hover:bg-green-700 active:bg-green-800 focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ActionColor.info =>
        'bg-blue-600 text-white hover:bg-blue-700 active:bg-blue-800 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-gray-900',
    };

    return '$baseClasses $sizeClasses $colorClasses';
  }
}
