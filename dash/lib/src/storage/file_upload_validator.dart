import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Configuration for file upload validation.
///
/// Provides configurable validation rules for:
/// - File size limits
/// - Allowed/blocked file extensions
/// - Allowed MIME types
/// - Filename sanitization
///
/// Example:
/// ```dart
/// final config = FileUploadValidationConfig(
///   maxFileSizeBytes: 10 * 1024 * 1024, // 10MB
///   allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf'],
///   allowedMimeTypes: ['image/*', 'application/pdf'],
/// );
///
/// final error = config.validate(fileData, fileName, mimeType);
/// if (error != null) {
///   return Response.badRequest(body: error);
/// }
/// ```
class FileUploadValidationConfig {
  /// Maximum file size in bytes. Default: 10MB.
  final int maxFileSizeBytes;

  /// Minimum file size in bytes. Default: 1 byte.
  final int minFileSizeBytes;

  /// List of allowed file extensions (lowercase, without dot).
  /// If empty, all extensions are allowed except blocked ones.
  final List<String> allowedExtensions;

  /// List of blocked file extensions (lowercase, without dot).
  /// These are always blocked regardless of allowedExtensions.
  final List<String> blockedExtensions;

  /// List of allowed MIME types.
  /// Supports wildcards like 'image/*'.
  /// If empty, MIME type validation is skipped.
  final List<String> allowedMimeTypes;

  /// Whether to allow files without extensions.
  final bool allowNoExtension;

  /// Maximum filename length after sanitization.
  final int maxFilenameLength;

  FileUploadValidationConfig({
    this.maxFileSizeBytes = 10 * 1024 * 1024, // 10MB default
    this.minFileSizeBytes = 1,
    this.allowedExtensions = const [],
    this.blockedExtensions = const [
      // Executable files
      'exe', 'bat', 'cmd', 'com', 'msi', 'scr', 'pif',
      // Script files
      'sh', 'bash', 'zsh', 'ps1', 'psm1', 'vbs', 'vbe', 'js', 'jse', 'ws', 'wsf', 'wsc', 'wsh',
      // Server-side scripts
      'php', 'php3', 'php4', 'php5', 'phtml', 'asp', 'aspx', 'jsp', 'cgi', 'pl', 'py', 'rb',
      // Archive files that could contain malware
      'jar', 'war',
      // Other dangerous files
      'dll', 'sys', 'drv', 'ocx', 'cpl', 'inf', 'reg', 'hta', 'htaccess',
    ],
    this.allowedMimeTypes = const [],
    this.allowNoExtension = false,
    this.maxFilenameLength = 255,
  });

  /// Default configuration for image uploads.
  factory FileUploadValidationConfig.images({
    int maxFileSizeBytes = 5 * 1024 * 1024, // 5MB for images
  }) {
    return FileUploadValidationConfig(
      maxFileSizeBytes: maxFileSizeBytes,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'ico', 'bmp'],
      allowedMimeTypes: [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp',
        'image/svg+xml',
        'image/x-icon',
        'image/bmp',
      ],
    );
  }

  /// Default configuration for document uploads.
  factory FileUploadValidationConfig.documents({
    int maxFileSizeBytes = 20 * 1024 * 1024, // 20MB for documents
  }) {
    return FileUploadValidationConfig(
      maxFileSizeBytes: maxFileSizeBytes,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'rtf', 'odt', 'ods', 'odp', 'csv'],
      allowedMimeTypes: [
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'text/plain',
        'application/rtf',
        'application/vnd.oasis.opendocument.text',
        'application/vnd.oasis.opendocument.spreadsheet',
        'application/vnd.oasis.opendocument.presentation',
        'text/csv',
      ],
    );
  }

  /// Validates a file upload.
  ///
  /// Returns null if valid, or an error message string if invalid.
  String? validate(Uint8List fileData, String fileName, String? mimeType) {
    // Check file size
    final sizeError = validateSize(fileData.length);
    if (sizeError != null) return sizeError;

    // Check filename
    final nameError = validateFilename(fileName);
    if (nameError != null) return nameError;

    // Check extension
    final extError = validateExtension(fileName);
    if (extError != null) return extError;

    // Check MIME type
    final mimeError = validateMimeType(mimeType);
    if (mimeError != null) return mimeError;

    // Check for double extensions (e.g., file.php.jpg)
    final doubleExtError = validateDoubleExtension(fileName);
    if (doubleExtError != null) return doubleExtError;

    return null;
  }

  /// Validates file size.
  String? validateSize(int sizeBytes) {
    if (sizeBytes < minFileSizeBytes) {
      return 'File is too small. Minimum size is ${_formatBytes(minFileSizeBytes)}.';
    }
    if (sizeBytes > maxFileSizeBytes) {
      return 'File is too large. Maximum size is ${_formatBytes(maxFileSizeBytes)}.';
    }
    return null;
  }

  /// Validates filename for dangerous characters and length.
  String? validateFilename(String fileName) {
    if (fileName.isEmpty) {
      return 'Filename cannot be empty.';
    }

    // Check for path traversal attempts
    if (fileName.contains('..') || fileName.contains('/') || fileName.contains('\\')) {
      return 'Invalid filename. Path traversal not allowed.';
    }

    // Check for null bytes
    if (fileName.contains('\x00')) {
      return 'Invalid filename. Null bytes not allowed.';
    }

    // Check length
    if (fileName.length > maxFilenameLength) {
      return 'Filename is too long. Maximum length is $maxFilenameLength characters.';
    }

    // Check for hidden files (starting with .)
    if (fileName.startsWith('.')) {
      return 'Hidden files (starting with .) are not allowed.';
    }

    return null;
  }

  /// Validates file extension.
  String? validateExtension(String fileName) {
    final extension = p.extension(fileName).toLowerCase().replaceFirst('.', '');

    // Check for no extension
    if (extension.isEmpty) {
      if (!allowNoExtension) {
        return 'Files must have an extension.';
      }
      return null;
    }

    // Always block dangerous extensions
    if (blockedExtensions.contains(extension)) {
      return 'File type ".$extension" is not allowed for security reasons.';
    }

    // If allowedExtensions is specified, check against it
    if (allowedExtensions.isNotEmpty && !allowedExtensions.contains(extension)) {
      return 'File type ".$extension" is not allowed. Allowed types: ${allowedExtensions.map((e) => '.$e').join(', ')}.';
    }

    return null;
  }

  /// Validates MIME type.
  String? validateMimeType(String? mimeType) {
    if (allowedMimeTypes.isEmpty) {
      return null; // No MIME type validation configured
    }

    if (mimeType == null || mimeType.isEmpty) {
      return 'File MIME type could not be determined.';
    }

    // Check if MIME type matches any allowed type (supports wildcards)
    for (final allowed in allowedMimeTypes) {
      if (_mimeTypeMatches(mimeType, allowed)) {
        return null;
      }
    }

    return 'File type "$mimeType" is not allowed.';
  }

  /// Validates for double extensions which could be used to bypass filters.
  /// Example: malware.php.jpg
  String? validateDoubleExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length <= 2) {
      return null; // Single extension is fine
    }

    // Check all extensions except the last one for dangerous types
    for (var i = 1; i < parts.length - 1; i++) {
      final ext = parts[i].toLowerCase();
      if (blockedExtensions.contains(ext)) {
        return 'Double extension with ".$ext" is not allowed for security reasons.';
      }
    }

    return null;
  }

  /// Checks if a MIME type matches an allowed pattern.
  bool _mimeTypeMatches(String mimeType, String pattern) {
    if (pattern.endsWith('/*')) {
      // Wildcard pattern (e.g., 'image/*')
      final prefix = pattern.substring(0, pattern.length - 1);
      return mimeType.startsWith(prefix);
    }
    return mimeType == pattern;
  }

  /// Formats bytes as human-readable string.
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Sanitizes a filename for safe storage.
///
/// - Removes path components
/// - Replaces dangerous characters
/// - Limits length
/// - Preserves extension
///
/// Returns the sanitized filename.
String sanitizeFilename(String fileName, {int maxLength = 255}) {
  // Get just the filename (remove any path)
  var sanitized = p.basename(fileName);

  // Remove null bytes
  sanitized = sanitized.replaceAll('\x00', '');

  // Replace dangerous characters with underscores
  sanitized = sanitized.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');

  // Replace multiple underscores/spaces with single underscore
  sanitized = sanitized.replaceAll(RegExp(r'[_\s]+'), '_');

  // Remove leading/trailing underscores and dots
  sanitized = sanitized.replaceAll(RegExp(r'^[._]+|[._]+$'), '');

  // Limit length while preserving extension
  if (sanitized.length > maxLength) {
    final ext = p.extension(sanitized);
    final name = p.basenameWithoutExtension(sanitized);
    final maxNameLength = maxLength - ext.length;
    sanitized = '${name.substring(0, maxNameLength)}$ext';
  }

  // If sanitization resulted in empty name, use a default
  if (sanitized.isEmpty || sanitized == p.extension(fileName)) {
    sanitized = 'file${p.extension(fileName)}';
  }

  return sanitized;
}
