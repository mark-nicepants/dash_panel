import 'package:dash/dash.dart';

import 'resources/post_resource.dart';
import 'resources/user_resource.dart';

Future<void> main({String dbDir = 'database'}) async {
  print('🚀 Dash Example Admin Panel\n');
  print('📁 Database directory: $dbDir\n');

  // Create and configure the admin panel
  final panel = Panel()
    ..setId('admin')
    ..setPath('/admin')
    ..database(DatabaseConfig.using(SqliteConnector('$dbDir/app.db')))
    ..registerResources([UserResource(), PostResource()]);

  // Boot the panel (connects to database)
  await panel.boot();

  // Start the server
  await panel.serve(host: 'localhost', port: 8080);

  // Keep the server running
  print('\n⌨️  Press Ctrl+C to stop the server\n');
}
