import 'dart:io';

/// Console utilities for colorful and formatted CLI output.
class ConsoleUtils {
  // ANSI color codes
  static const reset = '\x1B[0m';
  static const red = '\x1B[31m';
  static const green = '\x1B[32m';
  static const yellow = '\x1B[33m';
  static const blue = '\x1B[34m';
  static const magenta = '\x1B[35m';
  static const cyan = '\x1B[36m';
  static const white = '\x1B[37m';
  static const gray = '\x1B[90m';
  static const bold = '\x1B[1m';
  static const dim = '\x1B[2m';

  /// Print a success message with a green checkmark.
  static void success(String message) {
    print('$green✓$reset $message');
  }

  /// Print an error message with a red X.
  static void error(String message) {
    print('$red✗$reset $message');
  }

  /// Print a warning message with a yellow warning sign.
  static void warning(String message) {
    print('$yellow⚠$reset $message');
  }

  /// Print an info message with a blue info icon.
  static void info(String message) {
    print('$blueℹ$reset $message');
  }

  /// Print a header with emphasis.
  static void header(String message) {
    print('');
    print('$bold$cyan$message$reset');
    print('$gray${'─' * message.length}$reset');
  }

  /// Print a sub-header.
  static void subHeader(String message) {
    print('');
    print('$bold$message$reset');
  }

  /// Print a table row with columns.
  static void tableRow(List<String> columns, List<int> widths) {
    final buffer = StringBuffer();
    for (var i = 0; i < columns.length; i++) {
      buffer.write(columns[i].padRight(widths[i]));
    }
    print(buffer.toString());
  }

  /// Print a horizontal line.
  static void line([int length = 60]) {
    print('$gray${'─' * length}$reset');
  }

  /// Print a spinner while waiting.
  static Future<T> withSpinner<T>(String message, Future<T> Function() action) async {
    final frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    var frameIndex = 0;
    var running = true;

    // Only show spinner in TTY mode
    if (!stdout.hasTerminal) {
      print(message);
      return await action();
    }

    // Start spinner
    final timer = Stream.periodic(const Duration(milliseconds: 80), (_) {
      if (running) {
        stdout.write('\r$cyan${frames[frameIndex]}$reset $message');
        frameIndex = (frameIndex + 1) % frames.length;
      }
    }).listen((_) {});

    try {
      final result = await action();
      running = false;
      await timer.cancel();
      stdout.write('\r$green✓$reset $message\n');
      return result;
    } catch (e) {
      running = false;
      await timer.cancel();
      stdout.write('\r$red✗$reset $message\n');
      rethrow;
    }
  }

  /// Ask for confirmation.
  static bool confirm(String message, {bool defaultValue = false}) {
    final defaultStr = defaultValue ? 'Y/n' : 'y/N';
    stdout.write('$yellow?$reset $message [$defaultStr]: ');
    final input = stdin.readLineSync()?.toLowerCase() ?? '';
    if (input.isEmpty) return defaultValue;
    return input == 'y' || input == 'yes';
  }

  /// Format a number with thousands separators.
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
  }

  /// Format duration in a human-readable way.
  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 1) {
      return '${duration.inMilliseconds}ms';
    } else if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }

  /// Print a progress bar.
  static void progressBar(int current, int total, {String prefix = '', int width = 40}) {
    final percent = (current / total).clamp(0.0, 1.0);
    final filled = (percent * width).round();
    final empty = width - filled;
    final bar = '$green${'█' * filled}$gray${'░' * empty}$reset';
    final percentStr = '${(percent * 100).toStringAsFixed(0)}%'.padLeft(4);
    stdout.write('\r$prefix [$bar] $percentStr');
    if (current >= total) print('');
  }
}
