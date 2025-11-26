import 'package:dash/src/components/partials/forms/form_components.dart';
import 'package:dash/src/form/fields/field.dart';
import 'package:jaspr/jaspr.dart';

/// A toggle/switch field for boolean values.
///
/// This field displays a stylized switch toggle that provides
/// a more visual boolean input than a standard checkbox.
///
/// Example:
/// ```dart
/// Toggle.make('active')
///   .label('Active')
///   .onLabel('On')
///   .offLabel('Off'),
///
/// Toggle.make('public')
///   .label('Make public')
///   .helperText('When enabled, this will be visible to everyone')
///   .defaultValue(true),
/// ```
class Toggle extends FormField {
  /// Label shown when toggle is on.
  String? _onLabel;

  /// Label shown when toggle is off.
  String? _offLabel;

  /// Color when on (Tailwind color class).
  String _onColor = 'lime';

  /// Color when off (Tailwind color class).
  String _offColor = 'gray';

  /// Size of the toggle.
  ToggleSize _size = ToggleSize.md;

  /// The value when on.
  String _onValue = '1';

  /// The value when off.
  String _offValue = '0';

  Toggle(super.name);

  /// Creates a new toggle field.
  static Toggle make(String name) {
    return Toggle(name);
  }

  /// Sets the label shown when on.
  Toggle onLabel(String label) {
    _onLabel = label;
    return this;
  }

  /// Gets the on label.
  String? getOnLabel() => _onLabel;

  /// Sets the label shown when off.
  Toggle offLabel(String label) {
    _offLabel = label;
    return this;
  }

  /// Gets the off label.
  String? getOffLabel() => _offLabel;

  /// Sets the color when on.
  Toggle onColor(String color) {
    _onColor = color;
    return this;
  }

  /// Gets the on color.
  String getOnColor() => _onColor;

  /// Sets the color when off.
  Toggle offColor(String color) {
    _offColor = color;
    return this;
  }

  /// Gets the off color.
  String getOffColor() => _offColor;

  /// Sets the size.
  Toggle size(ToggleSize size) {
    _size = size;
    return this;
  }

  /// Gets the size.
  ToggleSize getSize() => _size;

  /// Sets the on value.
  Toggle onValue(String value) {
    _onValue = value;
    return this;
  }

  /// Gets the on value.
  String getOnValue() => _onValue;

  /// Sets the off value.
  Toggle offValue(String value) {
    _offValue = value;
    return this;
  }

  /// Gets the off value.
  String getOffValue() => _offValue;

  @override
  Component build(BuildContext context) {
    final inputId = getId();

    final defaultVal = getDefaultValue();
    final isChecked = defaultVal == true || defaultVal == 1 || defaultVal == '1' || defaultVal == _onValue;

    // Map internal size to FormToggleSize
    final toggleSize = switch (_size) {
      ToggleSize.sm => FormToggleSize.sm,
      ToggleSize.md => FormToggleSize.md,
      ToggleSize.lg => FormToggleSize.lg,
    };

    return FormToggleField(
      id: inputId,
      name: getName(),
      labelText: getLabel(),
      helperText: getHelperText(),
      onLabel: _onLabel,
      offLabel: _offLabel,
      onValue: _onValue,
      offValue: _offValue,
      checked: isChecked,
      onColor: _onColor,
      required: isRequired(),
      disabled: isDisabled(),
      size: toggleSize,
      extraClasses: getExtraClasses(),
    );
  }
}

/// Toggle size options.
enum ToggleSize { sm, md, lg }
