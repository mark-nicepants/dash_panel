import 'package:dash/src/components/partials/forms/form_components.dart';
import 'package:dash/src/form/fields/field.dart';
import 'package:jaspr/jaspr.dart';

/// A date picker field.
///
/// This field displays a native date input with optional
/// time selection and range constraints.
///
/// Example:
/// ```dart
/// DatePicker.make('birth_date')
///   .label('Date of Birth')
///   .maxDate(DateTime.now())
///   .displayFormat('MM/dd/yyyy'),
///
/// DatePicker.make('appointment')
///   .label('Appointment Date & Time')
///   .withTime()
///   .minDate(DateTime.now()),
///
/// DatePicker.make('start_date')
///   .label('Start Date')
///   .native(),
/// ```
class DatePicker extends FormField {
  /// Whether to include time selection.
  bool _withTime = false;

  /// Whether to only show time (no date).
  bool _timeOnly = false;

  /// Minimum allowed date.
  DateTime? _minDate;

  /// Maximum allowed date.
  DateTime? _maxDate;

  /// Display format (for custom pickers).
  String _displayFormat = 'yyyy-MM-dd';

  /// Whether to use native HTML date input.
  bool _native = true;

  /// First day of week (0 = Sunday, 1 = Monday).
  int _firstDayOfWeek = 1;

  /// Disabled dates.
  List<DateTime>? _disabledDates;

  /// Whether to close on selection.
  bool _closeOnSelect = true;

  DatePicker(super.name);

  /// Creates a new date picker field.
  static DatePicker make(String name) {
    return DatePicker(name);
  }

  /// Includes time selection.
  DatePicker withTime([bool withTime = true]) {
    _withTime = withTime;
    return this;
  }

  /// Checks if time is included.
  bool hasTime() => _withTime;

  /// Shows only time picker (no date).
  DatePicker timeOnly([bool timeOnly = true]) {
    _timeOnly = timeOnly;
    return this;
  }

  /// Checks if time only.
  bool isTimeOnly() => _timeOnly;

  /// Sets the minimum allowed date.
  DatePicker minDate(DateTime date) {
    _minDate = date;
    return this;
  }

  /// Gets the minimum date.
  DateTime? getMinDate() => _minDate;

  /// Sets the maximum allowed date.
  DatePicker maxDate(DateTime date) {
    _maxDate = date;
    return this;
  }

  /// Gets the maximum date.
  DateTime? getMaxDate() => _maxDate;

  /// Sets the display format.
  DatePicker displayFormat(String format) {
    _displayFormat = format;
    return this;
  }

  /// Gets the display format.
  String getDisplayFormat() => _displayFormat;

  /// Uses native HTML date input.
  DatePicker native([bool native = true]) {
    _native = native;
    return this;
  }

  /// Checks if using native input.
  bool isNative() => _native;

  /// Sets the first day of week.
  DatePicker firstDayOfWeek(int day) {
    _firstDayOfWeek = day;
    return this;
  }

  /// Gets the first day of week.
  int getFirstDayOfWeek() => _firstDayOfWeek;

  /// Sets disabled dates.
  DatePicker disabledDates(List<DateTime> dates) {
    _disabledDates = dates;
    return this;
  }

  /// Gets disabled dates.
  List<DateTime>? getDisabledDates() => _disabledDates;

  /// Sets whether to close on selection.
  DatePicker closeOnSelect([bool close = true]) {
    _closeOnSelect = close;
    return this;
  }

  /// Checks if should close on select.
  bool shouldCloseOnSelect() => _closeOnSelect;

  /// Sets the minimum date to today.
  DatePicker minToday() {
    _minDate = DateTime.now();
    return this;
  }

  /// Sets the maximum date to today.
  DatePicker maxToday() {
    _maxDate = DateTime.now();
    return this;
  }

  @override
  Component build(BuildContext context) {
    final inputId = getId();

    // Determine input type
    final inputType = _timeOnly
        ? InputType.time
        : _withTime
        ? 'datetime-local'
        : InputType.date;

    // Format dates for HTML5 inputs
    final attrs = <String, String>{};
    if (_minDate != null) {
      attrs['min'] = _formatDateForInput(_minDate!);
    }
    if (_maxDate != null) {
      attrs['max'] = _formatDateForInput(_maxDate!);
    }
    // Handle datetime-local type which Jaspr doesn't support directly
    if (inputType is String) {
      attrs['type'] = inputType;
    }

    // Default value
    final defaultVal = getDefaultValue();
    String? valueStr;
    if (defaultVal != null) {
      if (defaultVal is DateTime) {
        valueStr = _formatDateForInput(defaultVal);
      } else if (defaultVal is String) {
        valueStr = defaultVal;
      }
    }

    return FormFieldWrapper(
      extraClasses: getExtraClasses(),
      children: [
        // Label
        if (!isHidden()) FormLabel(labelText: getLabel(), forId: inputId, required: isRequired(), hint: getHint()),

        // Input
        FormInput(
          type: inputType is InputType ? inputType : InputType.text,
          id: inputId,
          name: getName(),
          value: valueStr,
          required: isRequired(),
          disabled: isDisabled(),
          readonly: isReadonly(),
          autofocus: shouldAutofocus(),
          autocomplete: getAutocomplete(),
          tabindex: getTabindex(),
          attributes: attrs.isEmpty ? null : attrs,
        ),

        // Helper text
        if (getHelperText() != null) FormHelperText(helperText: getHelperText()!),
      ],
    );
  }

  /// Formats a DateTime for HTML5 date/time inputs.
  String _formatDateForInput(DateTime date) {
    if (_timeOnly) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (_withTime) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
