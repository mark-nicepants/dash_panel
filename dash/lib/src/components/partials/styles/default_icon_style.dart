import 'package:jaspr/jaspr.dart';

/// Provides default icon styling (size and color) to descendant components.
///
/// Wrap a subtree with [DefaultIconStyle] to set default icon properties
/// that [Heroicon] components will inherit.
///
/// Example:
/// ```dart
/// DefaultIconStyle(
///   size: 24,
///   color: 'text-gray-400',
///   child: div([
///     Heroicon(HeroIcons.user),  // Uses size 24 and text-gray-400
///     Heroicon(HeroIcons.cog),   // Also uses size 24 and text-gray-400
///   ]),
/// )
/// ```
class DefaultIconStyle extends InheritedComponent {
  /// The default icon size in pixels.
  final int? size;

  /// The default icon color (Tailwind class or CSS color).
  final String? color;

  const DefaultIconStyle({this.size, this.color, required super.child, super.key});

  /// Retrieves the nearest [DefaultIconStyle] from the widget tree, if any.
  static DefaultIconStyle? maybeOf(BuildContext context) {
    return context.dependOnInheritedComponentOfExactType<DefaultIconStyle>();
  }

  /// Retrieves the nearest [DefaultIconStyle] from the widget tree.
  /// Throws if none is found.
  static DefaultIconStyle of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No DefaultIconStyle found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant DefaultIconStyle oldComponent) {
    return size != oldComponent.size || color != oldComponent.color;
  }
}
