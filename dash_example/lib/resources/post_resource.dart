import 'package:dash/dash.dart';

import '../models/post.dart';

/// Resource for managing blog posts in the admin panel.
class PostResource extends Resource<Post> {
  @override
  Type get model => Post;

  @override
  String? get navigationGroup => 'Content';
}
