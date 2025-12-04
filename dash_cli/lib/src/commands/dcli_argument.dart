import 'package:args/args.dart';

import 'completion_configuration.dart';

/// Unified argument definition for Dash CLI commands.
///
/// This class allows defining command arguments once and generating
/// both argParser configuration and completion configuration from
/// the same definition, eliminating duplication.
///
/// Example:
/// ```dart
/// class MyCommand extends BaseCommand {
///   static final _databaseArg = DcliArgument.option(
///     name: 'database',
///     abbr: 'd',
///     help: 'Path to database file',
///     completionType: CompletionType.file,
///     filePattern: '*.db',
///   );
///
///   static final _modelArg = DcliArgument.positional(
///     name: 'model',
///     help: 'The model name to seed',
///     completionType: CompletionType.model,
///   );
///
///   static final arguments = [_databaseArg, _modelArg];
///
///   MyCommand() {
///     DcliArgument.addToParser(argParser, arguments.whereType<_OptionArg>());
///   }
///
///   @override
///   CompletionConfiguration? getCompletionConfig() =>
///     DcliArgument.toCompletionConfig(
///       name: name,
///       description: description,
///       arguments: arguments,
///     );
/// }
/// ```
sealed class DcliArgument {
  const DcliArgument._({
    required this.name,
    required this.help,
    required this.completionType,
    this.values,
    this.filePattern,
  });

  /// Creates a named option argument (--name or -n).
  static DcliArgument option({
    required String name,
    required String help,
    String? abbr,
    String? defaultsTo,
    CompletionType completionType = CompletionType.string,
    List<String>? values,
    String? filePattern,
    bool mandatory = false,
    List<String>? aliases,
  }) => _OptionArg(
    name: name,
    help: help,
    abbr: abbr,
    defaultsTo: defaultsTo,
    completionType: completionType,
    values: values,
    filePattern: filePattern,
    mandatory: mandatory,
    aliases: aliases,
  );

  /// Creates a boolean flag argument (--flag, --no-flag).
  static DcliArgument flag({
    required String name,
    required String help,
    String? abbr,
    bool defaultsTo = false,
    bool negatable = true,
  }) => _FlagArg(name: name, help: help, abbr: abbr, defaultsTo: defaultsTo, negatable: negatable);

  /// Creates a positional argument.
  static DcliArgument positional({
    required String name,
    required String help,
    CompletionType completionType = CompletionType.string,
    List<String>? values,
    String? filePattern,
  }) =>
      _PositionalArg(name: name, help: help, completionType: completionType, values: values, filePattern: filePattern);

  /// The argument name.
  final String name;

  /// Help text for the argument.
  final String help;

  /// The type of completion to provide.
  final CompletionType completionType;

  /// Static values for enumeration type.
  final List<String>? values;

  /// File glob pattern for file type.
  final String? filePattern;

  /// Whether this is a positional argument.
  bool get isPositional;

  /// Whether this is a flag (boolean).
  bool get isFlag;

  /// Add all non-positional arguments to an [ArgParser].
  static void addToParser(ArgParser parser, Iterable<DcliArgument> arguments) {
    for (final arg in arguments) {
      switch (arg) {
        case _OptionArg():
          parser.addOption(
            arg.name,
            abbr: arg.abbr,
            help: arg.help,
            defaultsTo: arg.defaultsTo,
            mandatory: arg.mandatory,
            aliases: arg.aliases ?? const [],
            allowed: arg.values,
          );
        case _FlagArg():
          parser.addFlag(
            arg.name,
            abbr: arg.abbr,
            help: arg.help,
            defaultsTo: arg.defaultsTo,
            negatable: arg.negatable,
          );
        case _PositionalArg():
          // Positional args are not added to argParser
          break;
      }
    }
  }

  /// Build a [CompletionConfiguration] from arguments.
  static CompletionConfiguration toCompletionConfig({
    required String name,
    required String description,
    required Iterable<DcliArgument> arguments,
    List<String> aliases = const [],
  }) {
    final positionalArgs = <CompletionArgument>[];
    final options = <CompletionOption>[];

    for (final arg in arguments) {
      switch (arg) {
        case _PositionalArg():
          positionalArgs.add(
            CompletionArgument(
              name: arg.name,
              type: arg.completionType,
              description: arg.help,
              values: arg.values,
              filePattern: arg.filePattern,
            ),
          );
        case _OptionArg():
          options.add(
            CompletionOption(
              name: arg.name,
              abbr: arg.abbr,
              type: arg.completionType,
              description: arg.help,
              values: arg.values,
              filePattern: arg.filePattern,
            ),
          );
        case _FlagArg():
          options.add(
            CompletionOption(name: arg.name, abbr: arg.abbr, type: CompletionType.flag, description: arg.help),
          );
      }
    }

    return CompletionConfiguration(
      name: name,
      description: description,
      aliases: aliases,
      positionalArgs: positionalArgs,
      options: options,
    );
  }
}

/// Internal: Option argument.
class _OptionArg extends DcliArgument {
  const _OptionArg({
    required super.name,
    required super.help,
    this.abbr,
    this.defaultsTo,
    super.completionType = CompletionType.string,
    super.values,
    super.filePattern,
    this.mandatory = false,
    this.aliases,
  }) : super._();

  final String? abbr;
  final String? defaultsTo;
  final bool mandatory;
  final List<String>? aliases;

  @override
  bool get isPositional => false;

  @override
  bool get isFlag => false;
}

/// Internal: Flag argument.
class _FlagArg extends DcliArgument {
  const _FlagArg({required super.name, required super.help, this.abbr, this.defaultsTo = false, this.negatable = true})
    : super._(completionType: CompletionType.flag);

  final String? abbr;
  final bool defaultsTo;
  final bool negatable;

  @override
  bool get isPositional => false;

  @override
  bool get isFlag => true;
}

/// Internal: Positional argument.
class _PositionalArg extends DcliArgument {
  const _PositionalArg({
    required super.name,
    required super.help,
    super.completionType = CompletionType.string,
    super.values,
    super.filePattern,
  }) : super._();

  @override
  bool get isPositional => true;

  @override
  bool get isFlag => false;
}
