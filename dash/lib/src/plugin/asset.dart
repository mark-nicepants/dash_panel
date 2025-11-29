/// Base class for plugin assets (CSS, JS).
///
/// Assets are loaded in the HTML document and can be either
/// inline content or external URLs.
abstract class Asset {
  final String _id;
  final String _content;
  final bool _isUrl;

  Asset._(this._id, this._content, this._isUrl);

  /// Unique identifier for this asset.
  String get id => _id;

  /// The content (inline code) or URL.
  String get content => _content;

  /// Whether this asset is an external URL.
  bool get isUrl => _isUrl;

  /// Whether this asset is inline content.
  bool get isInline => !_isUrl;
}

/// A CSS asset for plugins.
///
/// Can be either a URL to an external stylesheet or inline CSS.
///
/// Example:
/// ```dart
/// // External stylesheet
/// CssAsset.url('my-plugin', 'https://cdn.example.com/styles.css')
///
/// // Inline CSS
/// CssAsset.inline('my-plugin', '''
///   .my-plugin-widget { padding: 1rem; }
/// ''')
/// ```
class CssAsset extends Asset {
  CssAsset._(super.id, super.content, super.isUrl) : super._();

  /// Creates a CSS asset from an external URL.
  static CssAsset url(String id, String url) => CssAsset._(id, url, true);

  /// Creates a CSS asset with inline content.
  static CssAsset inline(String id, String css) => CssAsset._(id, css, false);

  /// Renders the HTML for this asset.
  String render() {
    if (isUrl) {
      return '<link rel="stylesheet" href="$content" data-plugin="$id">';
    }
    return '<style data-plugin="$id">$content</style>';
  }
}

/// A JavaScript asset for plugins.
///
/// Can be either a URL to an external script or inline JavaScript.
///
/// Example:
/// ```dart
/// // External script
/// JsAsset.url('my-plugin', 'https://cdn.example.com/script.js')
///
/// // Inline JavaScript
/// JsAsset.inline('my-plugin', '''
///   console.log('Plugin loaded');
/// ''')
/// ```
class JsAsset extends Asset {
  final bool _defer;
  final bool _async;
  final bool _module;

  JsAsset._(super.id, super.content, super.isUrl, this._defer, this._async, this._module) : super._();

  /// Creates a JavaScript asset from an external URL.
  static JsAsset url(String id, String url, {bool defer = false, bool async = false, bool module = false}) =>
      JsAsset._(id, url, true, defer, async, module);

  /// Creates a JavaScript asset with inline content.
  static JsAsset inline(String id, String js, {bool module = false}) => JsAsset._(id, js, false, false, false, module);

  /// Renders the HTML for this asset.
  String render() {
    if (isUrl) {
      final attrs = <String>['src="$content"', 'data-plugin="$id"'];
      if (_defer) attrs.add('defer');
      if (_async) attrs.add('async');
      if (_module) attrs.add('type="module"');
      return '<script ${attrs.join(' ')}></script>';
    }

    final typeAttr = _module ? ' type="module"' : '';
    return '<script$typeAttr data-plugin="$id">$content</script>';
  }
}

/// Registry for managing plugin assets.
class AssetRegistry {
  final List<CssAsset> _cssAssets = [];
  final List<JsAsset> _jsAssets = [];

  /// Registers a CSS asset.
  void registerCss(CssAsset asset) {
    // Prevent duplicates
    if (!_cssAssets.any((a) => a.id == asset.id)) {
      _cssAssets.add(asset);
    }
  }

  /// Registers a JavaScript asset.
  void registerJs(JsAsset asset) {
    // Prevent duplicates
    if (!_jsAssets.any((a) => a.id == asset.id)) {
      _jsAssets.add(asset);
    }
  }

  /// Registers an asset (auto-detects type).
  void register(Asset asset) {
    if (asset is CssAsset) {
      registerCss(asset);
    } else if (asset is JsAsset) {
      registerJs(asset);
    }
  }

  /// Gets all registered CSS assets.
  List<CssAsset> get cssAssets => List.unmodifiable(_cssAssets);

  /// Gets all registered JavaScript assets.
  List<JsAsset> get jsAssets => List.unmodifiable(_jsAssets);

  /// Renders all CSS assets as HTML.
  String renderCss() {
    return _cssAssets.map((a) => a.render()).join('\n');
  }

  /// Renders all JavaScript assets as HTML.
  String renderJs() {
    return _jsAssets.map((a) => a.render()).join('\n');
  }

  /// Clears all registered assets.
  void clear() {
    _cssAssets.clear();
    _jsAssets.clear();
  }
}

/// Collects assets required for a specific page render.
///
/// This allows widgets and components to declare their asset dependencies,
/// which are then collected and rendered only on pages that need them.
///
/// Example:
/// ```dart
/// final collector = PageAssetCollector();
/// for (final widget in widgets) {
///   collector.collectFrom(widget);
/// }
/// final headAssets = collector.renderHeadAssets();
/// final bodyAssets = collector.renderBodyAssets();
/// ```
class PageAssetCollector {
  final Set<String> _registeredIds = {};
  final List<CssAsset> _headCss = [];
  final List<JsAsset> _headJs = [];
  final List<JsAsset> _bodyJs = [];

  /// Registers a CSS asset to be loaded in the head.
  void requireCss(CssAsset asset) {
    if (_registeredIds.contains(asset.id)) return;
    _registeredIds.add(asset.id);
    _headCss.add(asset);
  }

  /// Registers a JavaScript asset to be loaded in the head.
  void requireHeadJs(JsAsset asset) {
    if (_registeredIds.contains(asset.id)) return;
    _registeredIds.add(asset.id);
    _headJs.add(asset);
  }

  /// Registers a JavaScript asset to be loaded at end of body.
  void requireBodyJs(JsAsset asset) {
    if (_registeredIds.contains(asset.id)) return;
    _registeredIds.add(asset.id);
    _bodyJs.add(asset);
  }

  /// Collects assets from an [AssetProvider].
  void collectFrom(AssetProvider provider) {
    for (final asset in provider.requiredAssets) {
      if (asset is CssAsset) {
        requireCss(asset);
      } else if (asset is JsAsset) {
        // JS assets go to body by default for better performance
        requireBodyJs(asset);
      }
    }
  }

  /// Collects assets from multiple providers.
  void collectFromAll(Iterable<AssetProvider> providers) {
    for (final provider in providers) {
      collectFrom(provider);
    }
  }

  /// Renders CSS and head JS assets for the `<head>` section.
  String renderHeadAssets() {
    final buffer = StringBuffer();
    for (final css in _headCss) {
      buffer.writeln(css.render());
    }
    for (final js in _headJs) {
      buffer.writeln(js.render());
    }
    return buffer.toString();
  }

  /// Renders JS assets for the end of `<body>`.
  String renderBodyAssets() {
    final buffer = StringBuffer();
    for (final js in _bodyJs) {
      buffer.writeln(js.render());
    }
    return buffer.toString();
  }

  /// Whether any assets have been collected.
  bool get hasAssets => _headCss.isNotEmpty || _headJs.isNotEmpty || _bodyJs.isNotEmpty;

  /// Gets all collected CSS assets.
  List<CssAsset> get cssAssets => List.unmodifiable(_headCss);

  /// Gets all collected JS assets (head + body).
  List<JsAsset> get jsAssets => List.unmodifiable([..._headJs, ..._bodyJs]);
}

/// Mixin for classes that require specific assets to be loaded.
///
/// Implement this mixin on widgets, components, or other classes
/// that need CSS or JavaScript assets.
///
/// Example:
/// ```dart
/// class MyChartWidget extends Widget with AssetProvider {
///   @override
///   List<Asset> get requiredAssets => [
///     JsAsset.url('chartjs', 'https://cdn.jsdelivr.net/npm/chart.js'),
///   ];
/// }
/// ```
mixin AssetProvider {
  /// Returns the list of assets required by this provider.
  List<Asset> get requiredAssets => [];
}
