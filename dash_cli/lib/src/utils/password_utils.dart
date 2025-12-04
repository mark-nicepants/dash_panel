import 'package:bcrypt/bcrypt.dart';

/// Utility class for password hashing operations.
///
/// Uses bcrypt for secure password hashing with configurable rounds.
class PasswordUtils {
  /// Default number of rounds for bcrypt hashing.
  static const int defaultRounds = 12;

  /// Hash a plain text password using bcrypt.
  ///
  /// [plainPassword] - The plain text password to hash
  /// [rounds] - The bcrypt cost factor (default: 12)
  ///
  /// Returns the bcrypt hash string.
  static String hash(String plainPassword, {int rounds = defaultRounds}) {
    return BCrypt.hashpw(plainPassword, BCrypt.gensalt(logRounds: rounds));
  }

  /// Verify a plain text password against a bcrypt hash.
  ///
  /// [plainPassword] - The plain text password to verify
  /// [hash] - The bcrypt hash to compare against
  ///
  /// Returns true if the password matches the hash.
  static bool verify(String plainPassword, String hash) {
    try {
      return BCrypt.checkpw(plainPassword, hash);
    } catch (_) {
      return false;
    }
  }

  /// Check if a string looks like a bcrypt hash.
  ///
  /// Bcrypt hashes start with $2a$, $2b$, or $2y$ followed by cost factor.
  static bool isBcryptHash(String value) {
    return RegExp(r'^\$2[aby]\$\d{2}\$').hasMatch(value);
  }
}
