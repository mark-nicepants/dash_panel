import 'package:jaspr/jaspr.dart';

/// Badge variants
enum BadgeVariant { default_, primary, success, danger, warning, info }

/// Badge sizes
enum BadgeSize { sm, md, lg }

/// Badge component for status indicators and labels.
class Badge extends StatelessComponent {
  final String label;
  final BadgeVariant variant;
  final BadgeSize size;
  final Component? icon;

  const Badge({
    required this.label,
    this.variant = BadgeVariant.default_,
    this.size = BadgeSize.md,
    this.icon,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final baseClasses = 'inline-flex items-center gap-1.5 font-semibold rounded-full whitespace-nowrap';

    final variantClasses = switch (variant) {
      BadgeVariant.default_ => 'bg-gray-700 text-gray-300',
      BadgeVariant.primary => 'bg-blue-900 text-blue-300',
      BadgeVariant.success => 'bg-green-900 text-green-300',
      BadgeVariant.danger => 'bg-red-900 text-red-300',
      BadgeVariant.warning => 'bg-yellow-900 text-yellow-300',
      BadgeVariant.info => 'bg-blue-900 text-blue-300',
    };

    final sizeClasses = switch (size) {
      BadgeSize.sm => 'text-xs px-2 py-0.5',
      BadgeSize.md => 'text-xs px-2.5 py-1',
      BadgeSize.lg => 'text-sm px-3 py-1.5',
    };

    final classes = '$baseClasses $variantClasses $sizeClasses';

    return span(classes: classes, [if (icon != null) icon!, text(label)]);
  }
}
