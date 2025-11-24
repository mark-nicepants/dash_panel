import 'package:jaspr/jaspr.dart';

/// Button variants
enum ButtonVariant { primary, secondary, danger, ghost }

/// Button sizes
enum ButtonSize { sm, md, lg }

/// Reusable button component with consistent Tailwind styling.
class Button extends StatelessComponent {
  final String label;
  final ButtonVariant variant;
  final ButtonSize size;
  final ButtonType? type;
  final String? href;
  final Map<String, String>? attributes;
  final Component? icon;
  final bool disabled;
  final bool fullWidth;

  const Button({
    required this.label,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.type,
    this.href,
    this.attributes,
    this.icon,
    this.disabled = false,
    this.fullWidth = false,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final baseClasses =
        'inline-flex items-center justify-center gap-2 font-semibold rounded-lg transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed';

    final variantClasses = switch (variant) {
      ButtonVariant.primary =>
        'bg-lime-500 text-white hover:bg-lime-600 active:bg-lime-700 focus:ring-2 focus:ring-lime-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ButtonVariant.secondary =>
        'bg-gray-700 text-gray-300 hover:bg-gray-600 hover:text-gray-100 active:bg-gray-800 focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ButtonVariant.danger =>
        'bg-red-600 text-white hover:bg-red-700 active:bg-red-800 focus:ring-2 focus:ring-red-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ButtonVariant.ghost => 'text-gray-300 hover:bg-gray-700 hover:text-white active:bg-gray-800',
    };

    final sizeClasses = switch (size) {
      ButtonSize.sm => 'text-sm px-3 py-1.5',
      ButtonSize.md => 'text-sm px-4 py-2',
      ButtonSize.lg => 'text-base px-6 py-3',
    };

    final widthClass = fullWidth ? 'w-full' : '';
    final classes = '$baseClasses $variantClasses $sizeClasses $widthClass'.trim();

    final content = [if (icon != null) icon!, text(label)];

    if (href != null) {
      return a(href: href!, classes: classes, attributes: attributes, content);
    }

    return button(
      type: type ?? ButtonType.button,
      classes: classes,
      attributes: disabled ? {...?attributes, 'disabled': 'true'} : attributes,
      content,
    );
  }
}
