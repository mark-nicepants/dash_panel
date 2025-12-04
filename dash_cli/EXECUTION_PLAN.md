# Dash CLI Refactoring - Execution Plan

**Created:** 2024-12-04  
**Status:** ✅ Complete

## Overview

This document tracks the implementation of three major improvements to the Dash CLI:
1. New `db:create` command for interactive model creation
2. Generic completion system with `CompletionConfiguration`
3. Driver-agnostic database commands (read from `panel.yaml`)

---

## Phase 1: Shared Infrastructure ✅ [Complete]

### 1.1 Create Base Command Class
**File:** `lib/src/commands/base_command.dart`

Create an abstract base class that all commands extend:
- Provides access to `DashConfig` (panel.yaml configuration)
- Database connection factory based on driver config
- Common argument definitions (--database, --schemas)
- `CompletionConfiguration` interface for shell completions

```dart
abstract class BaseCommand extends Command<int> {
  // Config lazy loading
  DashConfig get config => _config ??= ConfigLoader.load();
  
  // Database connector factory
  DatabaseConnector getDatabase();
  
  // Shell completion configuration
  CompletionConfiguration getCompletionConfig();
}
```

### 1.2 Database Connector Abstraction
**File:** `lib/src/database/database_connector.dart`

Abstract database operations that work across drivers:
- `DatabaseConnector` interface
- `SqliteConnector` implementation
- Future: `PostgresConnector`, `MySqlConnector`

Methods:
- `List<String> getTables()`
- `List<Map<String, dynamic>> getTableInfo(String table)`
- `int insert(String table, Map<String, dynamic> data)`
- `List<Map<String, dynamic>> select(String query, [List<dynamic>? params])`
- `void execute(String query, [List<dynamic>? params])`
- `void close()`

### 1.3 Update ConfigLoader
**File:** `lib/src/utils/config_loader.dart`

Enhance to parse complete panel.yaml structure:
- Database driver type (sqlite, postgres, mysql)
- Database connection parameters
- Schema paths
- Server configuration

### 1.4 Password Hashing Utility
**File:** `lib/src/utils/password_utils.dart`

```dart
class PasswordUtils {
  static String hash(String plainPassword, {int rounds = 12});
  static bool verify(String plainPassword, String hash);
}
```

### 1.5 Add bcrypt Dependency
**File:** `pubspec.yaml`

Add `bcrypt: ^2.0.0` to dependencies.

---

## Phase 2: Completion Configuration System ✅ [Complete]

### 2.1 CompletionConfiguration Interface
**File:** `lib/src/commands/completion_configuration.dart`

```dart
class CompletionConfiguration {
  final String name;
  final String description;
  final List<String> aliases;
  final List<CompletionArgument> positionalArgs;
  final List<CompletionOption> options;
}

class CompletionArgument {
  final String name;
  final String? description;
  final CompletionType type; // enum, file, directory, model, table, custom
  final List<String>? staticValues;
  final String? dynamicSource; // e.g., 'models', 'tables'
}

class CompletionOption {
  final String name;
  final String? abbr;
  final String? description;
  final CompletionType type;
  final List<String>? staticValues;
}
```

### 2.2 Update Commands with CompletionConfiguration

Each command implements `getCompletionConfig()`:

```dart
@override
CompletionConfiguration getCompletionConfig() {
  return CompletionConfiguration(
    name: name,
    description: description,
    aliases: aliases,
    positionalArgs: [
      CompletionArgument(name: 'model', type: CompletionType.model),
      CompletionArgument(name: 'count', type: CompletionType.number),
    ],
    options: [
      CompletionOption(name: 'database', abbr: 'd', type: CompletionType.file),
      CompletionOption(name: 'verbose', abbr: 'v', type: CompletionType.flag),
    ],
  );
}
```

### 2.3 Update CompletionCommand

Generate shell completions dynamically from command configurations:
- Iterate all registered commands
- Call `getCompletionConfig()` on each
- Generate appropriate shell script

---

## Phase 3: db:create Command ✅ [Complete]

### 3.1 Create DbCreateCommand
**File:** `lib/src/commands/db_create_command.dart`

Interactive command to create a single model record:

**Arguments:**
- `<model>` - Model name (required, positional)
- `-d, --database` - Database path (from config if not specified)
- `-s, --schemas` - Schema directory path
- `--non-interactive` - Use generated values without prompting

**Flow:**
1. Load model schema from YAML
2. For each non-auto field:
   - Show field name, type, constraints
   - Prompt for value
   - If empty (Enter pressed), generate value using faker
   - If field is password type, hash with bcrypt
3. Validate all values against schema constraints
4. Insert into database
5. Display created record

**Special handling:**
- Password fields: Hash with bcrypt when not empty
- Foreign keys: Show available values from related table
- Enum fields: Show dropdown of valid options
- Timestamps: Auto-generate (skip prompting)

### 3.2 Field Value Generator
**File:** `lib/src/utils/field_generator.dart`

Extract faker-based generation logic from `DbSeedCommand`:
- Reusable across seed and create commands
- Handle all field types consistently
- Password fields generate random string + hash

---

## Phase 4: Update Existing Commands ✅ [Complete]

### 4.1 Refactor DbSeedCommand
- Extend `BaseCommand`
- Use `DatabaseConnector` instead of direct sqlite3
- Use shared `FieldGenerator`
- Implement `getCompletionConfig()`

### 4.2 Refactor DbClearCommand
- Extend `BaseCommand`
- Use `DatabaseConnector`
- Implement `getCompletionConfig()`

### 4.3 Refactor DbSchemaCommand
- Extend `BaseCommand`
- Use `DatabaseConnector`
- Implement `getCompletionConfig()`

### 4.4 Refactor GenerateModelsCommand
- Extend `BaseCommand`
- Implement `getCompletionConfig()`

### 4.5 Refactor Server Commands
- Extend `BaseCommand`
- Implement `getCompletionConfig()`

---

## File Structure After Refactoring

```
dash_cli/lib/src/
├── commands/
│   ├── base_command.dart          # Abstract base class with getDatabase()
│   ├── completion_configuration.dart # Completion config types
│   ├── completion_command.dart    # Dynamic shell completion generation
│   ├── db_clear_command.dart      # Uses Dash's DatabaseConnector
│   ├── db_create_command.dart     # Interactive record creation
│   ├── db_schema_command.dart     # Uses Dash's DatabaseConnector  
│   ├── db_seed_command.dart       # Uses shared FieldGenerator
│   ├── dcli_argument.dart         # Unified argument definitions
│   ├── generate_models_command.dart # Model code generation
│   ├── server_log_command.dart    # Server log viewing
│   └── server_status_command.dart # Server status checking
├── generators/
│   └── schema_parser.dart         # YAML schema parsing
└── utils/
    ├── config_loader.dart         # Uses PanelConfigLoader from Dash
    ├── console_utils.dart         # Terminal output helpers
    ├── field_generator.dart       # Faker-based value generation
    └── password_utils.dart        # BCrypt hashing

# Note: database/ folder was removed - CLI now uses Dash's DatabaseConnector
```

---

## Phase 5: Consolidation and Code Reuse ✅ [Complete]

These improvements reduce code duplication between Dash and Dash CLI by sharing common infrastructure.

> **Note:** Most of Phase 5 was already implemented when this document was created. The main change was 5.3 (Reuse Dash DatabaseConnector) which was completed on 2024-12-04.

### 5.1 Panel.applyConfig Without Path Parameter ✅
**Already implemented in** `dash/lib/src/panel/panel_config_loader.dart`

`PanelConfigLoader.findPanelConfig()` already searches for panel config by convention.
- Recursively search for `panel.yml` or `panel.yaml` starting from current directory
- Search up through parent directories until found or hit root
- Fall back to `schemas/panel.yaml` for backwards compatibility

```dart
extension PanelConfigExtension on Panel {
  /// Applies configuration from panel.yml/panel.yaml found by convention.
  ///
  /// Searches for panel.yml in:
  /// 1. Current directory
  /// 2. schemas/ directory
  /// 3. Parent directories (recursive)
  Panel applyConfig([String? configPath]) {
    final path = configPath ?? _findPanelConfig();
    if (path == null) {
      return this; // No config found, use defaults
    }
    // ... existing implementation
  }
  
  static String? _findPanelConfig([String? startPath]) {
    var current = Directory(startPath ?? Directory.current.path);
    while (true) {
      for (final name in ['panel.yml', 'panel.yaml']) {
        final file = File(p.join(current.path, name));
        if (file.existsSync()) return file.path;
        
        final schemasFile = File(p.join(current.path, 'schemas', name));
        if (schemasFile.existsSync()) return schemasFile.path;
      }
      
      final parent = current.parent;
      if (parent.path == current.path) break; // Hit root
      current = parent;
    }
    return null;
  }
}
```

### 5.2 Reuse PanelConfigLoader in CLI
**Files:**
- `dash_cli/lib/src/utils/config_loader.dart` - DELETE
- `dash_cli/lib/src/commands/base_command.dart` - UPDATE

Replace CLI's `ConfigLoader` with Dash's `PanelConfigLoader`:
- Import `PanelConfigData` from Dash
- Use the same config loading logic
- Start scanning from where `dcli` is executed
- Find first `panel.yml` by convention

### 5.3 Reuse Dash DatabaseConnector in CLI
**Files:**
- `dash_cli/lib/src/database/database_connector.dart` - DELETE
- `dash_cli/lib/src/database/sqlite_connector.dart` - DELETE
- `dash_cli/lib/src/commands/base_command.dart` - UPDATE

Replace CLI's database abstraction with Dash's:
- Import `DatabaseConnector` and `SqliteConnector` from Dash
- Add utility methods to Dash's connector as extension or base class methods:
  - `getTables()` - List all table names
  - `getTableInfo(table)` - Get column metadata
  - `getForeignKeys(table)` - Get FK info
  - `getIndexes(table)` - Get index info
  - `getRowCount(table)` - Count rows
  - `tableExists(table)` - Check if table exists
  - `getColumnValues(table, column)` - Get values for FK lookups
  - `disableForeignKeys()` / `enableForeignKeys()` - For bulk operations
  - `vacuum()` - Reclaim space after deletes

### 5.4 Create DcliArgument Unified Definition
**File:** `dash_cli/lib/src/commands/dcli_argument.dart`

Create a unified argument class that generates both:
- `argParser` options/flags
- `CompletionConfiguration` entries

```dart
/// Unified argument definition for CLI commands.
///
/// Generates both argParser options and CompletionConfiguration entries
/// from a single definition, reducing duplication.
class DcliArgument {
  final String name;
  final String? abbr;
  final String? description;
  final DcliArgType type;
  final bool isRequired;
  final dynamic defaultValue;
  final List<String>? allowedValues;
  final String? filePattern;
  
  const DcliArgument({
    required this.name,
    this.abbr,
    this.description,
    this.type = DcliArgType.string,
    this.isRequired = false,
    this.defaultValue,
    this.allowedValues,
    this.filePattern,
  });
  
  /// Add this argument to an ArgParser.
  void addToParser(ArgParser parser) {
    if (type == DcliArgType.flag) {
      parser.addFlag(
        name,
        abbr: abbr,
        help: description,
        defaultsTo: defaultValue as bool? ?? false,
      );
    } else {
      parser.addOption(
        name,
        abbr: abbr,
        help: description,
        defaultsTo: defaultValue?.toString(),
        allowed: allowedValues,
        mandatory: isRequired,
      );
    }
  }
  
  /// Convert to CompletionOption for shell completion.
  CompletionOption toCompletionOption() {
    return CompletionOption(
      name: name,
      abbr: abbr,
      description: description,
      type: _toCompletionType(),
      values: allowedValues,
      filePattern: filePattern,
    );
  }
  
  CompletionType _toCompletionType() => switch (type) {
    DcliArgType.flag => CompletionType.flag,
    DcliArgType.file => CompletionType.file,
    DcliArgType.directory => CompletionType.directory,
    DcliArgType.model => CompletionType.model,
    DcliArgType.table => CompletionType.table,
    DcliArgType.number => CompletionType.number,
    DcliArgType.enumeration => CompletionType.enumeration,
    _ => CompletionType.string,
  };
}

/// Positional argument definition.
class DcliPositionalArg {
  final String name;
  final String? description;
  final DcliArgType type;
  final bool isRequired;
  
  const DcliPositionalArg({
    required this.name,
    this.description,
    this.type = DcliArgType.string,
    this.isRequired = false,
  });
  
  CompletionArgument toCompletionArgument() {
    return CompletionArgument(
      name: name,
      description: description,
      type: _toCompletionType(),
    );
  }
  
  CompletionType _toCompletionType() => switch (type) {
    DcliArgType.model => CompletionType.model,
    DcliArgType.table => CompletionType.table,
    DcliArgType.number => CompletionType.number,
    _ => CompletionType.string,
  };
}

enum DcliArgType {
  string,
  number,
  flag,
  file,
  directory,
  model,
  table,
  enumeration,
}

/// Mixin providing argument definition helpers for commands.
mixin DcliArgumentsMixin on Command<int> {
  /// Define and register arguments.
  /// Call in constructor after super().
  void defineArguments(List<DcliArgument> args) {
    for (final arg in args) {
      arg.addToParser(argParser);
    }
  }
  
  /// Convert argument definitions to CompletionConfiguration.
  CompletionConfiguration buildCompletionConfig({
    required String name,
    required String description,
    List<String> aliases = const [],
    List<DcliPositionalArg> positionalArgs = const [],
    List<DcliArgument> options = const [],
  }) {
    return CompletionConfiguration(
      name: name,
      description: description,
      aliases: aliases,
      positionalArgs: positionalArgs.map((a) => a.toCompletionArgument()).toList(),
      options: options.map((a) => a.toCompletionOption()).toList(),
    );
  }
}
```

### 5.5 Update Commands to Use DcliArgument

Update all commands to use `DcliArgument` for defining their arguments:

```dart
class DbSeedCommand extends BaseCommand with DcliArgumentsMixin {
  // Define arguments once
  static const _args = [
    DcliArgument(
      name: 'database',
      abbr: 'd',
      description: 'Path to database file',
      type: DcliArgType.file,
      filePattern: '*.db',
    ),
    DcliArgument(
      name: 'schemas',
      abbr: 's',
      description: 'Path to schema YAML files',
      type: DcliArgType.directory,
    ),
    DcliArgument(
      name: 'verbose',
      abbr: 'v',
      description: 'Show detailed output',
      type: DcliArgType.flag,
    ),
    DcliArgument(
      name: 'list',
      abbr: 'l',
      description: 'List available models to seed',
      type: DcliArgType.flag,
    ),
  ];
  
  static const _positionalArgs = [
    DcliPositionalArg(
      name: 'model',
      description: 'Model name to seed',
      type: DcliArgType.model,
      isRequired: true,
    ),
    DcliPositionalArg(
      name: 'count',
      description: 'Number of records (default: 10)',
      type: DcliArgType.number,
    ),
  ];
  
  DbSeedCommand() {
    defineArguments(_args);
  }
  
  @override
  CompletionConfiguration getCompletionConfig() {
    return buildCompletionConfig(
      name: name,
      description: description,
      aliases: aliases,
      positionalArgs: _positionalArgs,
      options: _args,
    );
  }
}
```

---

## Progress Tracking

| Task | Status | Notes |
|------|--------|-------|
| 1.1 Create BaseCommand | ✅ Complete | |
| 1.2 Database Connector | ✅ Complete | |
| 1.3 Update ConfigLoader | ✅ Complete | |
| 1.4 Password Utils | ✅ Complete | |
| 1.5 Add bcrypt dependency | ✅ Complete | |
| 2.1 CompletionConfiguration | ✅ Complete | |
| 2.2 Update commands with config | ✅ Complete | |
| 2.3 Update CompletionCommand | ✅ Complete | |
| 3.1 Create DbCreateCommand | ✅ Complete | |
| 3.2 Field Value Generator | ✅ Complete | |
| 4.1 Refactor DbSeedCommand | ✅ Complete | |
| 4.2 Refactor DbClearCommand | ✅ Complete | |
| 4.3 Refactor DbSchemaCommand | ✅ Complete | |
| 4.4 Refactor GenerateModelsCommand | ✅ Complete | |
| 4.5 Refactor Server Commands | ✅ Complete | |
| 5.1 Panel.applyConfig without path | ✅ Complete | Was already implemented |
| 5.2 Reuse PanelConfigLoader | ✅ Complete | Was already implemented |
| 5.3 Reuse Dash DatabaseConnector | ✅ Complete | CLI now uses Dash's async DatabaseConnector |
| 5.4 Create DcliArgument | ✅ Complete | Was already implemented |
| 5.5 Update commands for DcliArgument | ✅ Complete | Was already implemented |
| Testing | ✅ Complete | All tests pass |

---

## Testing Plan

### Manual Tests
1. `dcli db:create User` - Create user interactively with bcrypt password
2. `dcli db:create User --non-interactive` - Auto-generate all fields
3. `dcli db:seed User 5` - Seed with proper driver
4. `dcli db:schema` - Show schema with any driver
5. `dcli db:clear -t users` - Clear table
6. `dcli completion zsh` - Generate dynamic completions
7. Login to admin panel with created user

### Automated Tests
- Unit tests for PasswordUtils
- Unit tests for FieldGenerator
- Unit tests for DatabaseConnector implementations
- Integration tests for commands

---

## Implementation Order

1. **Foundation first:**
   - Add bcrypt dependency
   - Create PasswordUtils
   - Create FieldGenerator (extract from DbSeedCommand)
   - Update ConfigLoader for panel.yaml

2. **Database abstraction:**
   - Create DatabaseConnector interface
   - Create SqliteConnector implementation

3. **Base infrastructure:**
   - Create CompletionConfiguration types
   - Create BaseCommand abstract class

4. **New command:**
   - Implement DbCreateCommand

5. **Migrate existing commands:**
   - Update each command to extend BaseCommand
   - Add completion configs to each

6. **Update completion:**
   - Refactor CompletionCommand to generate from configs

7. **Test everything**

---

*Last updated: 2024-12-04*
