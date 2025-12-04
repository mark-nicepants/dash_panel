/// Configuration for shell completion generation.
///
/// Commands implement this interface to provide completion hints
/// that are used to generate shell-specific completion scripts.
class CompletionConfiguration {
  const CompletionConfiguration({
    required this.name,
    required this.description,
    this.aliases = const [],
    this.positionalArgs = const [],
    this.options = const [],
  });

  /// The command name (e.g., 'db:seed').
  final String name;

  /// A brief description of the command.
  final String description;

  /// Alternative names for the command.
  final List<String> aliases;

  /// Positional arguments the command accepts.
  final List<CompletionArgument> positionalArgs;

  /// Named options/flags the command accepts.
  final List<CompletionOption> options;
}

/// Types of completions that can be generated.
enum CompletionType {
  /// A string with no special completion.
  string,

  /// A number.
  number,

  /// A boolean flag (no value needed).
  flag,

  /// A file path.
  file,

  /// A directory path.
  directory,

  /// A model name (from schema files).
  model,

  /// A database table name.
  table,

  /// A shell type (zsh, bash).
  shell,

  /// Static list of allowed values.
  enumeration,

  /// Custom completion logic.
  custom,
}

/// A positional argument for completion.
class CompletionArgument {
  const CompletionArgument({
    required this.name,
    required this.type,
    this.description,
    this.values,
    this.filePattern,
  });

  /// The argument name (for documentation).
  final String name;

  /// The type of completion to provide.
  final CompletionType type;

  /// A description of the argument.
  final String? description;

  /// Static values for [CompletionType.enumeration].
  final List<String>? values;

  /// File glob pattern for [CompletionType.file] (e.g., "*.db").
  final String? filePattern;
}

/// A named option for completion.
class CompletionOption {
  const CompletionOption({
    required this.name,
    required this.type,
    this.abbr,
    this.description,
    this.values,
    this.filePattern,
  });

  /// The full option name (without --).
  final String name;

  /// Short option (without -).
  final String? abbr;

  /// The type of completion to provide.
  final CompletionType type;

  /// A description of the option.
  final String? description;

  /// Static values for [CompletionType.enumeration].
  final List<String>? values;

  /// File glob pattern for [CompletionType.file].
  final String? filePattern;
}

/// Mixin for commands that provide completion configuration.
///
/// Commands should implement this to provide shell completion hints.
mixin CompletionConfigurable {
  /// Get the completion configuration for this command.
  ///
  /// Returns null if the command doesn't support custom completions.
  CompletionConfiguration? getCompletionConfig();
}
