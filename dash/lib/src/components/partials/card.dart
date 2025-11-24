import 'package:jaspr/jaspr.dart';

/// Card component for consistent container styling.
class Card extends StatelessComponent {
  final Component child;
  final String? customClasses;
  final EdgeInsets? padding;

  const Card({required this.child, this.customClasses, this.padding, super.key});

  @override
  Component build(BuildContext context) {
    final paddingClass = switch (padding) {
      EdgeInsets.none => '',
      EdgeInsets.sm => 'p-4',
      EdgeInsets.md => 'p-6',
      EdgeInsets.lg => 'p-8',
      _ => 'p-6', // default
    };

    final classes = 'bg-gray-800 rounded-xl border border-gray-700 shadow-lg $paddingClass ${customClasses ?? ''}'
        .trim();

    return div(classes: classes, [child]);
  }
}

/// Padding options for cards
enum EdgeInsets { none, sm, md, lg }
