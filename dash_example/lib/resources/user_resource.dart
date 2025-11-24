import 'package:dash/dash.dart';

import '../models/user.dart';

/// Resource for managing users in the admin panel.
class UserResource extends Resource<User> {
  @override
  Type get model => User;

  @override
  Heroicon get iconComponent => const Heroicon(HeroIcons.userGroup);

  @override
  String? get navigationGroup => 'Administration';
}
