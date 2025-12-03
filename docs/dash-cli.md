# Dash CLI

The Dash CLI (`dash_cli`) is a command-line interface for the Dash admin panel framework. It provides tools for:

- **Code Generation** - Generate models and resources from YAML schema files
- **Database Management** - Inspect schemas, seed data, and clear tables
- **Server Monitoring** - Check status, stream logs, and monitor health

## Quick Start

```bash
# Install the CLI
cd dash_cli && dart pub get

# Run commands
dart run bin/dash.dart <command> [arguments]

# Or activate globally
dart pub global activate --source path ./dash_cli
dash <command> [arguments]
```

## Commands Overview

| Command | Description |
|---------|-------------|
| `generate:models` | Generate Dart models from schema YAML files |
| `db:schema` | Display database table schemas |
| `db:seed <model> [count]` | Seed database with fake data |
| `db:clear` | Clear all data from tables |
| `server:status` | Display server status and health |
| `server:log` | Stream server logs |
| `completion` | Generate shell completion scripts |

## Code Generation

Generate Dart model classes from YAML schema definitions:

```bash
dash generate:models -s schemas/models -o lib
```

This reads all `.yaml` files in the schemas directory and generates:
- Model classes with Active Record pattern
- Resource classes for admin CRUD operations
- A barrel file (`models.dart`) with registration function

## Database Commands

### Schema Inspection

```bash
# View all tables with full details
dash db:schema

# View specific table
dash db:schema -t users

# Compact view
dash db:schema -c
```

### Database Seeding

The seeder generates realistic fake data based on your schema:

```bash
# List available models
dash db:seed --list

# Seed 100 users
dash db:seed User 100

# With verbose output
dash db:seed Post 50 -v
```

**Smart Data Generation:**

The seeder recognizes field names and types to generate appropriate data:

| Field Pattern | Generated Data |
|--------------|----------------|
| `email` | Fake email address |
| `name`, `fullname` | Fake person name |
| `password` | Bcrypt-like hash |
| `slug` | URL-friendly string |
| `content`, `body` | Lorem ipsum text |
| `avatar`, `image` | Placeholder image URL |
| `phone` | Phone number |
| `address`, `city` | Location data |
| Enum fields | Random valid value |
| Boolean (`isActive`) | Context-aware (80% true) |
| Foreign keys | Random existing ID |

### Clear Data

```bash
# Clear all tables (asks for confirmation)
dash db:clear

# Clear specific table
dash db:clear -t posts

# Skip confirmation
dash db:clear --force
```

## Server Monitoring

### Status Check

```bash
dash server:status
```

Output includes:
- Server status (running/offline)
- Version and uptime
- Response time
- Resource count
- Database connection status
- Memory usage
- Registered resources list

### Log Streaming

```bash
# Show recent logs
dash server:log

# Follow logs in real-time
dash server:log -f

# Show last 100 entries
dash server:log -n 100
```

## Shell Completion

Enable tab completion for faster command entry:

```bash
# Zsh (recommended for macOS)
dash completion zsh --install

# Bash
dash completion bash --install
```

After installation, restart your shell. You'll get completions for:
- Command names
- Options and flags
- Model names (for `db:seed`)
- Table names (for `db:schema -t`)

## Configuration

The CLI auto-discovers configuration from these locations:

1. `dash.yaml` in current directory
2. `schemas/panel.yaml`
3. `pubspec.yaml` under `dash:` key

Example `dash.yaml`:

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

## Server API

The CLI communicates with the running Dash server via REST endpoints:

| Endpoint | Description |
|----------|-------------|
| `GET /_cli/status` | Server status and health |
| `GET /_cli/logs` | Query log entries |
| `GET /_cli/health` | Simple health check |

The API is enabled by default in development mode. In production (when `DASH_ENV=production`), it's disabled for security.

## Development Workflow

Typical development session:

```bash
# Terminal 1: Start the server
dart run lib/main.dart

# Terminal 2: Watch logs
dash server:log -f

# Terminal 3: Work on code
dash generate:models  # After schema changes
dash db:seed User 10  # Add test data
dash server:status    # Verify server health
```

## Integration with Dash

The CLI is designed to work seamlessly with the Dash framework:

1. **Schema-Driven** - Uses the same YAML schemas as model generation
2. **Database Compatible** - Works directly with SQLite databases
3. **Server Integration** - Communicates via built-in CLI API endpoints
4. **Convention-Based** - Follows Dash naming and path conventions

## See Also

- [Model Schema Generator](model-schema-generator.md) - Schema YAML format
- [Database Migrations](database-migrations.md) - Migration system
- [dash_cli README](../dash_cli/README.md) - Full command reference
