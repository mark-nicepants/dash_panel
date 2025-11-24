import 'dart:io';

/// Loads and caches static resources (CSS, JS, HTML templates) from the resources directory.
class ResourceLoader {
  final String _htmlTemplate;
  final String _css;
  final String _js;
  final bool _useMinified;

  ResourceLoader._({required String htmlTemplate, required String css, required String js, required bool useMinified})
    : _htmlTemplate = htmlTemplate,
      _css = css,
      _js = js,
      _useMinified = useMinified;

  /// Initializes and loads all resources from disk.
  static Future<ResourceLoader> initialize() async {
    final useMinified = Platform.environment['DASH_ENV'] == 'production';

    print('🔧 Initializing ResourceLoader (${useMinified ? 'production' : 'development'} mode)...');

    final htmlTemplate = await _loadHtmlTemplate();
    final css = await _loadCss(useMinified);
    final js = await _loadAppJs(useMinified);

    print('✅ Resources loaded successfully');

    return ResourceLoader._(htmlTemplate: htmlTemplate, css: css, js: js, useMinified: useMinified);
  }

  /// Loads the HTML template.
  static Future<String> _loadHtmlTemplate() async {
    final file = File('dash/resources/index.html');
    return await file.readAsString();
  }

  /// Loads the main CSS file.
  static Future<String> _loadCss(bool useMinified) async {
    final cssPath = useMinified ? 'dash/resources/dist/css/dash.min.css' : 'dash/resources/dist/css/dash.css';

    final file = File(cssPath);
    if (await file.exists()) {
      return await file.readAsString();
    }

    print('⚠️  CSS file not found at $cssPath - minified: $useMinified');
    return '';
  }

  /// Loads the main application JavaScript.
  static Future<String> _loadAppJs(bool useMinified) async {
    final jsPath = useMinified ? 'dash/resources/dist/js/app.min.js' : 'dash/resources/dist/js/app.js';

    final file = File(jsPath);
    if (await file.exists()) {
      return await file.readAsString();
    }

    print('⚠️  JS file not found at $jsPath - minified: $useMinified');
    return '';
  }

  /// Renders an HTML template with the given variables.
  String renderTemplate({required String title, required String body}) {
    return _htmlTemplate
        .replaceAll('@title', title)
        .replaceAll('@styles', '<style>$_css</style>')
        .replaceAll('@scripts', '<script>$_js</script>')
        .replaceAll('@body', body);
  }

  /// Gets the loaded CSS content.
  String get css => _css;

  /// Gets the loaded JS content.
  String get js => _js;

  /// Gets the HTML template.
  String get htmlTemplate => _htmlTemplate;

  /// Whether production assets are being used.
  bool get isProduction => _useMinified;
}
