import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Command handler function type.
typedef CommandHandler = Future<void> Function(List<String> args);

/// A command that can be executed in the dev console.
class DevCommand {
  final String name;
  final String? shortName;
  final String description;
  final CommandHandler handler;
  final String? usage;

  const DevCommand({required this.name, this.shortName, required this.description, required this.handler, this.usage});
}

/// Interactive development console for the Dash server.
///
/// Allows developers to interact with the running server through
/// keyboard commands. Supports built-in commands and custom commands.
class DevConsole {
  final Map<String, DevCommand> _commands = {};
  final List<String> _commandHistory = [];
  StreamSubscription<String>? _inputSubscription;
  bool _isRunning = false;

  /// Callback when server should restart.
  Future<void> Function()? onRestart;

  /// Callback when server should stop.
  Future<void> Function()? onStop;

  /// Callback to clear terminal.
  void Function()? onClear;

  DevConsole() {
    _registerBuiltInCommands();
  }

  /// Whether the console is currently running.
  bool get isRunning => _isRunning;

  /// Registers a custom command.
  void registerCommand(DevCommand command) {
    _commands[command.name.toLowerCase()] = command;
    // Also register short name if provided
    if (command.shortName != null) {
      _commands[command.shortName!.toLowerCase()] = command;
    }
  }

  /// Starts listening for user input.
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    _printWelcome();

    // Enable line mode for stdin
    stdin.echoMode = true;
    stdin.lineMode = true;

    // Listen for stdin input
    _inputSubscription = stdin.transform(utf8.decoder).transform(const LineSplitter()).listen(_handleInput);
  }

  /// Stops listening for user input.
  Future<void> stop() async {
    _isRunning = false;
    await _inputSubscription?.cancel();
    _inputSubscription = null;
  }

  void _registerBuiltInCommands() {
    registerCommand(
      DevCommand(
        name: 'help',
        shortName: 'h',
        description: 'Show available commands',
        handler: (_) async => _printHelp(),
      ),
    );

    registerCommand(
      DevCommand(
        name: 'restart',
        shortName: 'r',
        description: 'Restart the server (hot restart)',
        handler: (_) async {
          if (onRestart != null) {
            print('\n🔄 Restarting server...\n');
            await onRestart!();
          } else {
            print('\n⚠️  Restart not available\n');
          }
        },
      ),
    );

    registerCommand(
      DevCommand(
        name: 'quit',
        shortName: 'q',
        description: 'Stop the server and exit',
        handler: (_) async {
          print('\n👋 Shutting down...\n');
          if (onStop != null) {
            await onStop!();
          }
          exit(0);
        },
      ),
    );

    registerCommand(
      DevCommand(
        name: 'clear',
        shortName: 'c',
        description: 'Clear the terminal',
        handler: (_) async {
          if (onClear != null) {
            onClear!();
          } else {
            // ANSI escape codes to clear screen
            print('\x1B[2J\x1B[0;0H');
          }
        },
      ),
    );

    registerCommand(
      DevCommand(name: 'routes', description: 'List all registered routes', handler: (_) async => _printRoutes()),
    );

    registerCommand(
      DevCommand(
        name: 'resources',
        description: 'List all registered resources',
        handler: (_) async => _printResources(),
      ),
    );

    registerCommand(
      DevCommand(
        name: 'open',
        shortName: 'o',
        description: 'Open server URL in browser',
        handler: (_) async {
          print('\n🌐 Opening in browser...\n');
          // Will be overridden by PanelServer with actual URL
        },
      ),
    );

    registerCommand(
      DevCommand(name: 'status', description: 'Show server status', handler: (_) async => _printStatus()),
    );
  }

  Future<void> _handleInput(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    _commandHistory.add(trimmed);

    final parts = trimmed.split(RegExp(r'\s+'));
    final commandName = parts.first.toLowerCase();
    final args = parts.skip(1).toList();

    final command = _commands[commandName];
    if (command != null) {
      try {
        await command.handler(args);
      } catch (e) {
        print('\n❌ Error executing command: $e\n');
      }
    } else {
      print('\n❓ Unknown command: $commandName');
      print('   Type "help" for available commands\n');
    }
  }

  void _printWelcome() {
    print('');
    print('┌─────────────────────────────────────────────┐');
    print('│  🎯 Dash Dev Console                        │');
    print('│  Type "help" or "h" for available commands  │');
    print('└─────────────────────────────────────────────┘');
    print('');
  }

  void _printHelp() {
    print('');
    print('📖 Available Commands:');
    print('');

    for (final cmd in _commands.values.toSet().toList()) {
      final cmdName = cmd.shortName != null ? '${cmd.shortName}, ${cmd.name}' : cmd.name;
      print('  ${_formatCommand(cmdName)}  ${cmd.description}');
    }

    print('');
  }

  String _formatCommand(String cmd) => cmd.padRight(12);

  void _printRoutes() {
    // This needs to be set from outside with actual routes
    print('');
    print('🛤️  Registered Routes:');
    print('');
    print('   (Routes will be listed when connected to panel)');
    print('');
  }

  void _printResources() {
    // This needs to be set from outside with actual resources
    print('');
    print('📦 Registered Resources:');
    print('');
    print('   (Resources will be listed when connected to panel)');
    print('');
  }

  void _printStatus() {
    // This will be overridden by PanelServer
    print('');
    print('📊 Server Status:');
    print('');
    print('   (Status will be shown when connected to panel)');
    print('');
  }

  /// Sets a callback to print routes with actual data.
  void setRoutePrinter(void Function() printer) {
    _commands['routes'] = DevCommand(
      name: 'routes',
      description: 'List all registered routes',
      handler: (_) async => printer(),
    );
  }

  /// Sets a callback to print resources with actual data.
  void setResourcePrinter(void Function() printer) {
    _commands['resources'] = DevCommand(
      name: 'resources',
      description: 'List all registered resources',
      handler: (_) async => printer(),
    );
  }
}
