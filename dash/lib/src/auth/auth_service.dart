import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Authentication service for the Dash admin panel.
///
/// Handles user authentication, session management, and password verification.
class AuthService {
  final Map<String, DashUser> _users = {};
  final Map<String, String> _sessions = {}; // sessionId -> email

  AuthService() {
    // Add default admin user for development
    addUser(
      DashUser(email: 'admin@example.com', passwordHash: _hashPassword('password'), name: 'Admin User', role: 'admin'),
    );
  }

  /// Hash a password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Add a user to the authentication system
  void addUser(DashUser user) {
    _users[user.email] = user;
  }

  /// Attempt to authenticate with email and password
  /// Returns a session token if successful, null otherwise
  String? login(String email, String password) {
    final user = _users[email];
    if (user == null) {
      return null;
    }

    final passwordHash = _hashPassword(password);
    if (user.passwordHash != passwordHash) {
      return null;
    }

    // Generate session token
    final sessionId = _generateSessionId(email);
    _sessions[sessionId] = email;

    return sessionId;
  }

  /// Logout by removing the session
  void logout(String sessionId) {
    _sessions.remove(sessionId);
  }

  /// Check if a session is valid
  bool isAuthenticated(String? sessionId) {
    if (sessionId == null) {
      return false;
    }
    return _sessions.containsKey(sessionId);
  }

  /// Get the user for a session
  DashUser? getUser(String? sessionId) {
    if (sessionId == null) {
      return null;
    }
    final email = _sessions[sessionId];
    if (email == null) {
      return null;
    }
    return _users[email];
  }

  /// Generate a session ID
  String _generateSessionId(String email) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$email:$timestamp';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}

/// User model for authentication
class DashUser {
  final String email;
  final String passwordHash;
  final String name;
  final String role;

  const DashUser({required this.email, required this.passwordHash, required this.name, required this.role});
}
