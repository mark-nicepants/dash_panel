// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated barrel file for all models

import 'package:dash_example/models/post.dart';
import 'package:dash_example/models/user.dart';
import 'package:dash_example/resources/post_resource.dart';
import 'package:dash_example/resources/user_resource.dart';

export 'package:dash_example/models/post.dart';
export 'package:dash_example/models/user.dart';
export 'package:dash_example/resources/post_resource.dart';
export 'package:dash_example/resources/user_resource.dart';

/// Registers all generated models with their resources.
///
/// This function registers each model with its metadata and
/// associates it with its corresponding Resource class.
///
/// Example:
/// ```dart
/// void main() {
///   registerAllModels();
///   // ... rest of your app
/// }
/// ```
void registerAllModels() {
  Post.register(PostResource.new);
  User.register(UserResource.new);
}
