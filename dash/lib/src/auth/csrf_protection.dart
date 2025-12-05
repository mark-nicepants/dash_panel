import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';

/// CSRF (Cross-Site Request Forgery) protection service.
///
/// Provides token generation and validation for protecting state-changing
/// operations (POST, PUT, DELETE, PATCH) from CSRF attacks.
///
/// ## How it works:
/// 1. Generate a token per session using [generateToken]
/// 2. Include the token in forms as a hidden field named `_csrf_token`
/// 3. Validate the token on form submission using [validateToken] or [csrfMiddleware]
///
/// ## Security:
/// - Tokens are bound to session IDs using HMAC-SHA256
/// - Tokens include timestamps to limit validity window
/// - Uses cryptographically secure random number generation
///
/// References:
/// - https://owasp.org/www-community/attacks/csrf
/// - https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html
///
/// Example:
/// ```dart
/// // Generate token for a form
/// final token = CsrfProtection.generateToken(sessionId);
///
/// // In form HTML
/// <input type="hidden" name="_csrf_token" value="$token">
///
/// // Validate on submission
/// if (!CsrfProtection.validateToken(formData['_csrf_token'], sessionId)) {
///   return Response.forbidden('Invalid CSRF token');
/// }
/// ```
class CsrfProtection {
  /// The form field name for the CSRF token.
  static const String tokenFieldName = '_csrf_token';

  /// Secret key for HMAC signing.
  /// In production, this should be loaded from environment/config.
  static String _secretKey = _generateSecretKey();

  /// Token validity duration (default: 4 hours).
  static Duration tokenValidity = const Duration(hours: 4);

  /// Generates a CSRF token bound to the given session ID.
  ///
  /// The token format is: `{timestamp}.{randomBytes}.{signature}`
  ///
  /// [sessionId] - The session ID to bind the token to.
  /// Returns a URL-safe base64 encoded token string.
  static String generateToken(String sessionId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = _generateRandomBytes(16);
    final randomString = base64Url.encode(randomBytes).replaceAll('=', '');

    // Create payload
    final payload = '$timestamp.$randomString';

    // Sign with HMAC-SHA256
    final signature = _sign(payload, sessionId);

    return '$payload.$signature';
  }

  /// Validates a CSRF token against the session ID.
  ///
  /// Checks:
  /// 1. Token format is valid
  /// 2. Token is not expired
  /// 3. Signature matches (token bound to session)
  ///
  /// [token] - The token from the form submission.
  /// [sessionId] - The current session ID.
  /// Returns true if the token is valid, false otherwise.
  static bool validateToken(String? token, String? sessionId) {
    if (token == null || token.isEmpty || sessionId == null || sessionId.isEmpty) {
      return false;
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return false;
      }

      final timestamp = int.parse(parts[0]);
      final randomString = parts[1];
      final signature = parts[2];

      // Check expiration
      final tokenTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(tokenTime) > tokenValidity) {
        return false;
      }

      // Verify signature
      final payload = '$timestamp.$randomString';
      final expectedSignature = _sign(payload, sessionId);

      // Constant-time comparison to prevent timing attacks
      return _secureCompare(signature, expectedSignature);
    } catch (e) {
      return false;
    }
  }

  /// Signs a payload using HMAC-SHA256.
  static String _sign(String payload, String sessionId) {
    final key = utf8.encode('$_secretKey:$sessionId');
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Generates cryptographically secure random bytes.
  static List<int> _generateRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  /// Generates a secret key for HMAC signing.
  static String _generateSecretKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Constant-time string comparison to prevent timing attacks.
  static bool _secureCompare(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Allows setting a custom secret key (for testing or configuration).
  ///
  /// **Important**: In production, set this to a secure, persistent value
  /// from environment variables.
  static void setSecretKey(String key) {
    _secretKey = key;
  }
}

/// Middleware that validates CSRF tokens on state-changing requests.
///
/// Protects POST, PUT, DELETE, and PATCH requests by requiring a valid
/// CSRF token in the request body.
///
/// The token can be submitted as:
/// - Form field: `_csrf_token`
/// - JSON body field: `_csrf_token`
/// - Header: `X-CSRF-Token`
///
/// Requests that don't require validation:
/// - GET, HEAD, OPTIONS requests (safe methods)
/// - Requests without a session cookie
/// - Requests to paths in [excludePaths]
///
/// Example:
/// ```dart
/// final pipeline = Pipeline()
///   .addMiddleware(csrfMiddleware(
///     sessionCookieName: 'dash_session',
///     excludePaths: ['/api/webhooks'],
///   ))
///   .addHandler(myHandler);
/// ```
Middleware csrfMiddleware({
  String sessionCookieName = 'dash_session',
  List<String> excludePaths = const [],
  String? basePath,
}) {
  // Safe HTTP methods that don't require CSRF validation
  const safeMethods = {'GET', 'HEAD', 'OPTIONS'};

  return (Handler innerHandler) {
    return (Request request) async {
      // Skip safe methods
      if (safeMethods.contains(request.method)) {
        return innerHandler(request);
      }

      final path = request.url.path;

      // Skip excluded paths
      for (final excludePath in excludePaths) {
        if (path.startsWith(excludePath) || path == excludePath) {
          return innerHandler(request);
        }
      }

      // Get session ID from cookie
      final sessionId = _parseSessionId(request, sessionCookieName);
      if (sessionId == null) {
        // No session = no CSRF protection needed (will be rejected by auth anyway)
        return innerHandler(request);
      }

      // Try to get token from header first (for AJAX requests)
      final token = request.headers['x-csrf-token'];

      // If not in header, need to read body
      // Note: This means we need to buffer the body for both CSRF check and handler
      if (token == null) {
        // For form submissions, token should be in form data
        // We'll let the router/handler validate this after parsing
        // Add a context value so handlers can perform validation
        final updatedRequest = request.change(context: {...request.context, 'csrf_session_id': sessionId});
        return innerHandler(updatedRequest);
      }

      // Validate token from header
      if (!CsrfProtection.validateToken(token, sessionId)) {
        return Response.forbidden('Invalid or expired CSRF token', headers: {'content-type': 'text/plain'});
      }

      return innerHandler(request);
    };
  };
}

/// Parses session ID from request cookies.
String? _parseSessionId(Request request, String cookieName) {
  final cookies = request.headers['cookie'];
  if (cookies == null) return null;

  final cookieList = cookies.split(';');
  for (final cookie in cookieList) {
    final parts = cookie.trim().split('=');
    if (parts.length == 2 && parts[0] == cookieName) {
      return parts[1];
    }
  }
  return null;
}

/// Extension to get CSRF session ID from request context.
extension CsrfRequestExtension on Request {
  /// Gets the session ID stored for CSRF validation.
  String? get csrfSessionId => context['csrf_session_id'] as String?;
}

/// Validates CSRF token from form data.
///
/// Call this in form handlers after parsing form data.
///
/// Returns true if valid, false otherwise.
bool validateCsrfToken(Map<String, dynamic> formData, String? sessionId) {
  final token = formData[CsrfProtection.tokenFieldName]?.toString();
  return CsrfProtection.validateToken(token, sessionId);
}
