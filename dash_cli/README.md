# Dash CLI

Command-line interface for the Dash admin panel framework. Provides model generation, database management, and server monitoring tools.

## Installation

```bash
# From within your Dash project
dart pub global activate --source path ./dash_cli

# Or install the executable directly
cd dash_cli && dart pub get
```

## Usage

```bash
dash <command> [arguments]
```

## Available Commands

### Code Generation

#### `generate:models`

Generate Dart model and resource classes from schema YAML files.

```bash
# Generate models from default location (schemas/models -> lib)
dash generate:models

# Specify custom paths
dash generate:models -s path/to/schemas -o lib/src

# Verbose output
dash generate:models -v

# Force overwrite existing resource files
dash generate:models --force
```

**Options:**
- `-s, --schemas` - Path to schema YAML files (default: `schemas/models`)
- `-o, --output` - Output directory for generated code (default: `lib`)
- `-f, --force` - Overwrite existing resource files
- `-v, --verbose` - Show detailed output

### Database Commands

#### `db:schema`

Display database table schemas with column information, indexes, and foreign keys.

```bash
# Show all tables
dash db:schema

# Specify database path
dash db:schema -d storage/app.db

# Show specific table only
dash db:schema -t users

# Compact output (just column names)
dash db:schema -c
```

**Options:**
- `-d, --database` - Path to SQLite database file (default: `storage/app.db`)
- `-t, --table` - Show only specific table
- `-c, --compact` - Compact output without column details

**Example Output:**
```
📊 Database Schema
──────────────────
users (63 rows)
───────────────────────────────────────────────────────────────────────────
Column                   Type           Null    Primary   Default        
───────────────────────────────────────────────────────────────────────────
id                       INTEGER        YES     ✓ PK                     
name                     TEXT           NO                               
email                    TEXT           NO                               
role                     TEXT           NO                               
  Indexes:
    • sqlite_autoindex_users_1: email (UNIQUE)
```

#### `db:seed`

Seed the database with fake data based on model schema.

```bash
# List available models
dash db:seed --list

# Seed 100 users
dash db:seed User 100

# Seed with custom schema path
dash db:seed User 50 -s example/schemas/models

# Verbose output
dash db:seed User 10 -v
```

**Options:**
- Model name (positional) - The model to seed (e.g., `User`, `Post`)
- Count (positional) - Number of records to create (default: 10)
- `-d, --database` - Path to SQLite database file (default: `storage/app.db`)
- `-s, --schemas` - Path to schema YAML files (default: `schemas/models`)
- `-v, --verbose` - Show detailed output
- `-l, --list` - List available models

**Smart Data Generation:**
The seeder inspects your schema and generates appropriate fake data:
- `email` fields → fake email addresses
- `name` fields → fake names
- `password` fields → bcrypt-like hashes
- `slug` fields → URL-friendly slugs
- `content`/`body` fields → lorem ipsum paragraphs
- `avatar`/`image` fields → placeholder image URLs
- Enum fields → random selection from allowed values
- Boolean fields → context-aware (e.g., `isActive` → 80% true)

#### `db:clear`

Clear all data from database tables (keeps table structure).

```bash
# Clear all tables (with confirmation)
dash db:clear

# Clear specific table
dash db:clear -t users

# Skip confirmation
dash db:clear --force
```

**Options:**
- `-d, --database` - Path to SQLite database file
- `-t, --table` - Clear only specific table
- `-f, --force` - Skip confirmation prompt

### Server Commands

#### `server:status`

Display server status and health information.

```bash
# Check default server
dash server:status

# Check custom server URL
dash server:status --url http://localhost:3000 --path /admin
```

**Options:**
- `--url` - Server URL (default: `http://localhost:8080`)
- `--path` - Admin panel base path (default: `/admin`)

**Example Output:**
```
📊 Server Status
────────────────

  ● Status:        Running
  ○ Version:       0.1.0
  ○ Response time: 44ms
  ○ Uptime:        5m 30s

Resources
  ○ Resources:     3 registered
  ● Database:      Connected

Registered Resources
  ○ Post (/post)
  ○ Tag (/tag)
  ○ User (/user)
```

#### `server:log`

Stream server logs to the console.

```bash
# Show last 50 log entries
dash server:log

# Show last N lines
dash server:log -n 100

# Follow logs in real-time (like tail -f)
dash server:log -f
```

**Options:**
- `-f, --follow` - Follow log output (like `tail -f`)
- `-n, --lines` - Number of lines to show (default: 50)
- `--url` - Server URL
- `--path` - Admin panel base path

### Shell Completion

#### `completion`

Generate shell completion scripts for auto-complete support.

```bash
# Generate Zsh completion script
dash completion zsh

# Install Zsh completion
dash completion zsh --install

# Generate Bash completion script
dash completion bash

# Install Bash completion
dash completion bash --install
```

**Zsh Setup:**
After installing, add to your `~/.zshrc`:
```bash
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
```

Then restart your shell or run `source ~/.zshrc`.

## Server API

The CLI communicates with the Dash server via a REST API. This API is automatically enabled in development mode.

**Endpoints:**
- `GET /_cli/status` - Server status and health information
- `GET /_cli/logs` - Query log entries
- `GET /_cli/health` - Simple health check

To disable the CLI API in production, set the environment variable:
```bash
DASH_ENV=production dart run your_app.dart
```

## Configuration

The CLI looks for configuration in the following order:
1. `dash.yaml` in current directory
2. `schemas/panel.yaml`
3. `pubspec.yaml` (under `dash:` key)
4. Command-line arguments (highest priority)

**Example `dash.yaml`:**
```yaml
database:
  path: storage/app.db

schemas:
  path: schemas/models

output:
  path: lib

server:
  url: http://localhost
  port: 8080
  basePath: /admin
```

## Examples

### Setting up a new project

```bash
# Generate models from schema files
dash generate:models -s schemas/models -o lib

# Seed initial test data
dash db:seed User 10
dash db:seed Post 50

# Check schema
dash db:schema
```

### Development workflow

```bash
# Terminal 1: Run the server
dart run lib/main.dart

# Terminal 2: Monitor logs
dash server:log -f

# Terminal 3: Check status
dash server:status
```

### Database management

```bash
# View all tables and their structure
dash db:schema

# View specific table
dash db:schema -t users

# Seed test data
dash db:seed User 100 -v

# Clear and reseed
dash db:clear -t users --force
dash db:seed User 50
```

## Troubleshooting

### "Schemas directory not found"
Specify the correct path to your schema files:
```bash
dash generate:models -s path/to/schemas
```

### "Database not found"
The database file doesn't exist. Make sure your Dash server has been started at least once to create the database.

### "Cannot connect to server"
The server must be running for `server:status` and `server:log` commands. Start it with:
```bash
dart run lib/main.dart
```

### "CLI API not enabled"
The CLI API is disabled in production mode. For local testing, ensure `DASH_ENV` is not set to `production`.

## License

MIT License - See LICENSE file for details.
