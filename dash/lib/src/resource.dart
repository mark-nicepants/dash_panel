import 'package:jaspr/jaspr.dart';

import 'components/heroicon.dart';
import 'model/model.dart';

/// Base class for all Dash resources.
///
/// A [Resource] represents a model or entity in your application that can be
/// managed through the admin panel. It defines how the data is displayed,
/// created, edited, and deleted.
///
/// Example:
/// ```dart
/// class UserResource extends Resource<User> {
///   @override
///   String get label => 'Users';
///
///   @override
///   String get singularLabel => 'User';
///
///   @override
///   Type get model => User;
/// }
/// ```
abstract class Resource<T extends Model> {
  /// The model class associated with this resource.
  Type get model;

  /// The plural label for this resource (e.g., "Users").
  /// Defaults to the model name with an 's' suffix.
  String get label => '${_modelName}s';

  /// The singular label for this resource (e.g., "User").
  /// Defaults to the model name.
  String get singularLabel => _modelName;

  /// Gets the model name from the Type.
  String get _modelName => model.toString();

  /// The icon component to display for this resource.
  Component get iconComponent => const Heroicon(HeroIcons.documentText);

  /// The navigation group this resource belongs to.
  /// Defaults to 'Main' if not specified.
  String? get navigationGroup => 'Main';

  /// The sort order for this resource in navigation.
  /// Defaults to 0.
  int get navigationSort => 0;

  /// Whether this resource should be shown in navigation.
  bool get shouldRegisterNavigation => true;

  /// The URL slug for this resource (e.g., "users").
  /// Defaults to lowercase plural label with spaces replaced by hyphens.
  String get slug => label.toLowerCase().replaceAll(' ', '-');
}
