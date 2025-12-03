import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dash_cli/src/utils/console_utils.dart';

/// Generate shell completion scripts.
///
/// Usage:
///   dash completion [shell]
///
/// Shells:
///   zsh     Generate Zsh completion script
///   bash    Generate Bash completion script
class CompletionCommand extends Command<int> {
  CompletionCommand() {
    argParser.addFlag(
      'install',
      abbr: 'i',
      help: 'Install the completion script to your shell config',
      defaultsTo: false,
    );
  }
  @override
  final String name = 'completion';

  @override
  final String description = 'Generate shell completion scripts';

  @override
  final String invocation = 'dcli completion [shell]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    final install = argResults!['install'] as bool;

    final shell = rest.isNotEmpty ? rest[0] : _detectShell();

    switch (shell.toLowerCase()) {
      case 'zsh':
        if (install) {
          return await _installZshCompletion();
        }
        print(_generateZshCompletion());
        return 0;

      case 'bash':
        if (install) {
          return await _installBashCompletion();
        }
        print(_generateBashCompletion());
        return 0;

      default:
        ConsoleUtils.error('Unsupported shell: $shell');
        print('');
        print('Supported shells: zsh, bash');
        return 1;
    }
  }

  String _detectShell() {
    final shell = Platform.environment['SHELL'] ?? '';
    if (shell.contains('zsh')) return 'zsh';
    if (shell.contains('bash')) return 'bash';
    return 'zsh'; // Default
  }

  String _generateZshCompletion() {
    return '''
#compdef dcli

# Dash CLI Zsh Completion
# Install: dcli completion zsh > ~/.zsh/completions/_dcli
# Or: dcli completion zsh --install

_dcli_commands() {
  local -a commands
  commands=(
    'generate\\:models:Generate Dart model and resource classes from schema YAML files'
    'db\\:schema:Display database table schemas'
    'db\\:seed:Seed the database with fake data'
    'db\\:clear:Clear all data from database tables'
    'server\\:log:Stream server logs to the console'
    'server\\:status:Display server status and health'
    'completion:Generate shell completion scripts'
    'help:Display help for a command'
  )
  _describe 'command' commands
}

_dcli_db_seed_models() {
  local -a models
  # Look for schema files in common locations
  local schema_dirs=("schemas/models" "schemas" "lib/schemas")
  for dir in "\$schema_dirs[@]"; do
    if [[ -d "\$dir" ]]; then
      models=(\${(f)"\$(ls \$dir/*.yaml 2>/dev/null | xargs -I {} basename {} .yaml)"})
      if [[ \${#models[@]} -gt 0 ]]; then
        _describe 'model' models
        return
      fi
    fi
  done
}

_dcli_db_schema_tables() {
  local db_path="storage/app.db"
  if [[ -f "\$db_path" ]]; then
    local -a tables
    tables=(\${(f)"\$(sqlite3 \$db_path "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'" 2>/dev/null)"})
    _describe 'table' tables
  fi
}

_dcli() {
  local curcontext="\$curcontext" state line
  typeset -A opt_args

  _arguments -C \\
    '1: :_dcli_commands' \\
    '*::arg:->args'

  case \$state in
    args)
      case \$line[1] in
        generate:models|gen:models|g:m)
          _arguments \\
            '-s[Schema directory]:directory:_files -/' \\
            '--schemas[Schema directory]:directory:_files -/' \\
            '-o[Output directory]:directory:_files -/' \\
            '--output[Output directory]:directory:_files -/' \\
            '-f[Overwrite existing files]' \\
            '--force[Overwrite existing files]' \\
            '-v[Verbose output]' \\
            '--verbose[Verbose output]'
          ;;
        db:schema|schema)
          _arguments \\
            '-d[Database path]:file:_files -g "*.db"' \\
            '--database[Database Path]:file:_files -g "*.db"' \\
            '-t[Table Name]:table:_dcli_db_schema_tables' \\
            '--table[Table Name]:table:_dcli_db_schema_tables' \\
            '-c[Compact output]' \\
            '--compact[Compact output]'
          ;;
        db:seed|seed)
          _arguments \\
            '1:model:_dcli_db_seed_models' \\
            '2:count:' \\
            '-d[Database path]:file:_files -g "*.db"' \\
            '--database[Database path]:file:_files -g "*.db"' \\
            '-s[Schema directory]:directory:_files -/' \\
            '--schemas[Schema directory]:directory:_files -/' \\
            '-v[Verbose output]' \\
            '--verbose[Verbose output]' \\
            '-l[List available models]' \\
            '--list[List available models]'
          ;;
        db:clear|clear)
          _arguments \\
            '-d[Database path]:file:_files -g "*.db"' \\
            '--database[Database path]:file:_files -g "*.db"' \\
            '-t[Table Name]:table:_dcli_db_schema_tables' \\
            '--table[Table Name]:table:_dcli_db_schema_tables' \\
            '-f[Skip confirmation]' \\
            '--force[Skip confirmation]'
          ;;
        server:log|log|logs)
          _arguments \\
            '-f[Follow log output]' \\
            '--follow[Follow log output]' \\
            '-n[Number of lines]:lines:' \\
            '--lines[Number of lines]:lines:' \\
            '--url[Server URL]:url:' \\
            '--path[Admin panel path]:path:'
          ;;
        server:status|status)
          _arguments \\
            '--url[Server URL]:url:' \\
            '--path[Admin panel path]:path:'
          ;;
        completion)
          _arguments \\
            '1:shell:(zsh bash)' \\
            '-i[Install to shell config]' \\
            '--install[Install to shell config]'
          ;;
      esac
      ;;
  esac
}

_dcli "\$@"
''';
  }

  String _generateBashCompletion() {
    return '''
# Dash CLI Bash Completion
# Install: dcli completion bash > /etc/bash_completion.d/dcli
# Or: dcli completion bash >> ~/.bashrc

_dcli_completions() {
  local cur prev commands
  COMPREPLY=()
  cur="\${COMP_WORDS[COMP_CWORD]}"
  prev="\${COMP_WORDS[COMP_CWORD-1]}"

  commands="generate:models db:schema db:seed db:clear server:log server:status completion help"

  if [[ \${COMP_CWORD} -eq 1 ]]; then
    COMPREPLY=(\$(compgen -W "\$commands" -- "\$cur"))
    return 0
  fi

  case "\${COMP_WORDS[1]}" in
    generate:models|gen:models|g:m)
      COMPREPLY=(\$(compgen -W "-s --schemas -o --output -f --force -v --verbose" -- "\$cur"))
      ;;
    db:schema|schema)
      COMPREPLY=(\$(compgen -W "-d --database -t --table -c --compact" -- "\$cur"))
      ;;
    db:seed|seed)
      if [[ \${COMP_CWORD} -eq 2 ]]; then
        # Try to list models from schema files
        local models=""
        for dir in schemas/models schemas lib/schemas; do
          if [[ -d "\$dir" ]]; then
            models=\$(ls \$dir/*.yaml 2>/dev/null | xargs -I {} basename {} .yaml)
            break
          fi
        done
        COMPREPLY=(\$(compgen -W "\$models" -- "\$cur"))
      else
        COMPREPLY=(\$(compgen -W "-d --database -s --schemas -v --verbose -l --list" -- "\$cur"))
      fi
      ;;
    db:clear|clear)
      COMPREPLY=(\$(compgen -W "-d --database -t --table -f --force" -- "\$cur"))
      ;;
    server:log|log|logs)
      COMPREPLY=(\$(compgen -W "-f --follow -n --lines --url --path" -- "\$cur"))
      ;;
    server:status|status)
      COMPREPLY=(\$(compgen -W "--url --path" -- "\$cur"))
      ;;
    completion)
      if [[ \${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=(\$(compgen -W "zsh bash" -- "\$cur"))
      else
        COMPREPLY=(\$(compgen -W "-i --install" -- "\$cur"))
      fi
      ;;
  esac

  return 0
}

complete -F _dcli_completions dcli
''';
  }

  Future<int> _installZshCompletion() async {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) {
      ConsoleUtils.error('Could not determine home directory');
      return 1;
    }

    // Try common zsh completion directories
    final completionDirs = ['$home/.zsh/completions', '$home/.zfunc', '/usr/local/share/zsh/site-functions'];

    String? targetDir;
    for (final dir in completionDirs) {
      if (Directory(dir).existsSync()) {
        targetDir = dir;
        break;
      }
    }

    // Create default directory if none exist
    if (targetDir == null) {
      targetDir = '$home/.zsh/completions';
      try {
        Directory(targetDir).createSync(recursive: true);
      } catch (e) {
        ConsoleUtils.error('Could not create completion directory: $e');
        return 1;
      }
    }

    final targetFile = '$targetDir/_dash';

    try {
      File(targetFile).writeAsStringSync(_generateZshCompletion());
      ConsoleUtils.success('Installed completion to $targetFile');
      print('');
      print('Add the following to your ~/.zshrc if not already present:');
      print('');
      print('  ${ConsoleUtils.cyan}fpath=($targetDir \$fpath)${ConsoleUtils.reset}');
      print('  ${ConsoleUtils.cyan}autoload -Uz compinit && compinit${ConsoleUtils.reset}');
      print('');
      print('Then restart your shell or run:');
      print('  ${ConsoleUtils.cyan}source ~/.zshrc${ConsoleUtils.reset}');
      print('');
      return 0;
    } catch (e) {
      ConsoleUtils.error('Failed to install completion: $e');
      return 1;
    }
  }

  Future<int> _installBashCompletion() async {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) {
      ConsoleUtils.error('Could not determine home directory');
      return 1;
    }

    // Try system completion directory first
    final systemDir = '/etc/bash_completion.d';
    if (Directory(systemDir).existsSync()) {
      final targetFile = '$systemDir/dcli';
      try {
        File(targetFile).writeAsStringSync(_generateBashCompletion());
        ConsoleUtils.success('Installed completion to $targetFile');
        print('');
        print('Restart your shell to enable completions.');
        return 0;
      } catch (_) {
        // Fall through to user directory
      }
    }

    // Fall back to user's bashrc
    final bashrc = '$home/.bashrc';
    try {
      final content = File(bashrc).existsSync() ? File(bashrc).readAsStringSync() : '';

      if (content.contains('_dcli_completions')) {
        ConsoleUtils.info('Bash completion already installed');
        return 0;
      }

      File(bashrc).writeAsStringSync('$content\n\n# Dash CLI completion\n${_generateBashCompletion()}\n');

      ConsoleUtils.success('Installed completion to $bashrc');
      print('');
      print('Restart your shell or run:');
      print('  ${ConsoleUtils.cyan}source ~/.bashrc${ConsoleUtils.reset}');
      print('');
      return 0;
    } catch (e) {
      ConsoleUtils.error('Failed to install completion: $e');
      return 1;
    }
  }
}
