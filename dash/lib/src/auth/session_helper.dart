import 'dart:io';

import 'package:shelf/shelf.dart';

/// Cookie name for the session ID.
const String _sessionCookieName = 'dash_session';

/// Helper class for managing request session data.
///
/// Provides secure session cookie management with:
/// - HttpOnly flag (prevents JavaScript access)
/// - SameSite=Strict (prevents CSRF attacks)
/// - Secure flag in production (HTTPS only)
class SessionHelper {
  /// Parses the session ID from request cookies.
  ///
  /// Returns the session ID if found, null otherwise.
  static String? parseSessionId(Request request) {
    final cookies = request.headers['cookie'];
    if (cookies == null) return null;

    final cookieList = cookies.split(';');
    for (final cookie in cookieList) {
      final parts = cookie.trim().split('=');
      if (parts.length == 2 && parts[0] == _sessionCookieName) {
        return parts[1];
      }
    }
    return null;
  }

  /// Creates a Set-Cookie header value for the session.
  ///
  /// Security attributes:
  /// - HttpOnly: Prevents JavaScript access to cookie
  /// - SameSite=Strict: Prevents CSRF attacks by not sending cookie on cross-site requests
  /// - Secure: Only sends cookie over HTTPS (production only)
  ///
  /// The Secure flag is automatically applied when DASH_ENV=production.
  static String createSessionCookie(String sessionId) {
    final attributes = ['$_sessionCookieName=$sessionId', 'Path=/', 'HttpOnly', 'SameSite=Strict'];

    // Add Secure flag in production (HTTPS only)
    if (_isProduction) {
      attributes.add('Secure');
    }

    return attributes.join('; ');
  }

  /// Creates a Set-Cookie header value to clear the session.
  ///
  /// Uses the same security attributes as [createSessionCookie] to ensure
  /// the cookie is properly cleared across all contexts.
  static String clearSessionCookie() {
    final attributes = ['$_sessionCookieName=', 'Path=/', 'HttpOnly', 'SameSite=Strict', 'Max-Age=0'];

    // Add Secure flag in production (HTTPS only)
    if (_isProduction) {
      attributes.add('Secure');
    }

    return attributes.join('; ');
  }

  /// Whether the application is running in production mode.
  ///
  /// Checks the DASH_ENV environment variable.
  static bool get _isProduction => Platform.environment['DASH_ENV'] == 'production';
}
