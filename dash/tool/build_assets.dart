import 'dart:io';

/// Builds CSS and JavaScript assets for production.
Future<void> main() async {
  print('🔨 Building assets...');

  // Check if node_modules exists
  final nodeModules = Directory('dash/node_modules');
  if (!await nodeModules.exists()) {
    print('📦 Installing npm dependencies...');
    await Process.run('npm', ['install'], workingDirectory: 'dash');
  }

  // Build CSS with PostCSS
  print('🎨 Processing CSS...');
  final cssResult = await Process.run('npx', [
    'postcss',
    'resources/css/dash.css',
    '--use',
    'autoprefixer',
    '--use',
    'cssnano',
    '-o',
    'resources/dist/css/dash.min.css',
  ], workingDirectory: 'dash');

  if (cssResult.exitCode != 0) {
    print('❌ CSS build failed: ${cssResult.stderr}');
    exit(1);
  }

  // Build JavaScript with esbuild
  print('📦 Bundling JavaScript...');
  final jsResult = await Process.run('npx', [
    'esbuild',
    'resources/js/app.js',
    '--bundle',
    '--minify',
    '--format=iife',
    '--outfile=resources/dist/js/app.min.js',
  ], workingDirectory: 'dash');

  if (jsResult.exitCode != 0) {
    print('❌ JS build failed: ${jsResult.stderr}');
    exit(1);
  }

  print('✅ Assets built successfully!');
  print('   CSS: dash/resources/dist/css/dash.min.css');
  print('   JS:  dash/resources/dist/js/app.min.js');
}
