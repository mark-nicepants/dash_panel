# Dash - Copilot Instructions

> **Dash** (Dart Admin/System Hub) is a FilamentPHP-inspired admin panel framework for Dart.

## Quick Reference

**What is Dash?** A server-side rendered website framework for Dart, inspired by FilamentPHP. It provides CRUD operations, forms, tables, and authentication out of the box.

**Key Concepts:**
- **Resource** = Model + Table + Form (defines how an entity is managed in the admin)
- **Model** = Active Record ORM with fluent query builder
- **FormField** = Input component with `dehydrateValue()` for DB conversion and `hydrateValue()` for display
- **Panel** = The main app orchestrator

## Development Workflow

### Running & Testing with Playwright

When fixing bugs or testing features interactively:

1. **Start the server with the example project** 
 - Run via VSCode task: Start Dash Example Server
 - Ensure it's running at `http://localhost:8080`.
 - If you get port in use errors. use `lsof -i :8080` to find and kill the process using it and restart the server.

2. **Use Playwright browser tools** to navigate and interact:
   - Navigate: `browser_navigate` to `http://localhost:8080/admin/login`
   - Fill forms: `browser_fill_form` or `browser_type`
   - Click: `browser_click` with element ref
   - Take snapshots: `browser_snapshot` to see current page state

3. **Login credentials**: `admin@example.com` / `password`

4. **After code changes**, restart the server to pick up changes
note: Sessions are saved between server restarts. So a simple refresh of the page after a restart should keep you logged in.

### Bug Fixing Approach

1. **Reproduce the bug** - Use Playwright to navigate and trigger the issue
2. **Check the logs** - Read `storage/logs/dash_YYYYMMDD_HHMM.log` for errors and debug info
3. **Add debug output** - Print statements in key locations (router, resource methods)
4. **Trace the flow** - Follow data through: Form submission → Resource → Model → Database
5. **Identify the layer** - Is it presentation, application, domain, or infrastructure?
7. **Test the fix** - Use Playwright to verify, then write unit tests
8. **Clean up debug output** - Remove print statements before committing

### Reading Application Logs

Dash writes logs to log files per server run in `storage/logs/`. Always check these logs when debugging:

```bash
# Read today's logs
cat storage/logs/dash_$(date +%Y%m%d_%H%M%S).log

# Tail the logs for real-time monitoring
tail -f storage/logs/dash_$(date +%Y%m%d_%H%M).log

# Search for errors
grep -i error storage/logs/dash_*.log

# Show last 50 lines of today's log
tail -50 storage/logs/dash_$(date +%Y%m%d_%H%M%S).log
```

**Log format:** `[YYYY-MM-DD HH:MM:SS] [LEVEL  ] message`

**Log levels:** `debug`, `info`, `warning`, `error`, `request`, `query`

The logs contain:
- HTTP request/response info (method, path, status code, duration)
- Database queries (when query logging is enabled)
- Errors and exceptions
- Application events

## Tech Stack

- **Dart** - Primary language
- **Jaspr** - HTML/SSR component rendering framework
- **Alpine.js** - Client-side state management (toggles, collapsibles, modals)
- **Tailwind CSS** - Utility-first styling
- **Shelf** - HTTP server

## Core Principles

1. **SOLID Principles** - Follow single responsibility, open/closed, Liskov substitution, interface segregation, and dependency inversion
2. **Fluent Builder APIs** - All configuration uses method chaining for readability
3. **Convention over Configuration** - Smart defaults, minimal required setup
4. **Server-Side Rendering** - Full page renders with traditional navigation
5. **Type Safety** - Leverage Dart's type system with generics
6. **Reusable Components** - Create and use Jaspr components for UI elements
7. **Fields Own Their Conversion** - Each FormField type handles its own value conversion in `dehydrateValue()`

## Component Architecture

### Component Hierarchy

- **Layout Components** - Page wrappers with navigation (`DashLayout`)
- **Page Components** - Full pages (`ResourceIndex`, `ResourceForm`, `ResourceView`)
- **Partial Components** - Reusable UI elements (`Button`, `Badge`, `Card`, `PageHeader`)
- **Form Components** - Input wrappers with styling and validation feedback

### Component Composition

Build complex UIs by composing smaller components:
- Pages compose layout + partials + form/table renderers
- Partials are self-contained with their own styling logic
- Use enums for variants rather than string-based configuration

---

## Code Patterns

### 1. Fluent Builder API

All configurable classes use method chaining. Configure tables and forms by chaining methods like `columns()`, `searchable()`, `sortable()`, `required()`, and `defaultSort()`.

### 2. Static Factory Methods

Always provide a `make()` factory method for configurable classes. This is the primary way to create instances and enables the fluent API pattern.

### 3. Generic Typing for Fluent Methods

Use generic type parameters in base class methods to preserve the concrete type through method chaining. Return `this as T` to maintain type safety.

### 4. Jaspr Components

Extend `StatelessComponent` and implement `build()`. Use `const` constructors, pass children as list arguments, and apply Tailwind classes via the `classes` parameter.

**Component Rules:**
- Use `const` constructors where possible
- Children go in a list as the last positional argument
- Use `classes` for Tailwind CSS classes
- Use `attributes` map for custom HTML attributes (`x-*`, `data-*`)

### 5. Resource Pattern

Resources bridge models to the admin UI:
- Override `table()` to configure list view columns, sorting, and actions
- Override `form()` to configure create/edit fields and validation
- Override action hooks (`indexHeaderActions`, `formActions`) for custom behaviors
- Resources own CRUD operations (`getRecords`, `createRecord`, `updateRecord`, `deleteRecord`)

### 6. Model Pattern (Active Record)

Models represent database entities:
- Extend `Model` base class
- Implement `table`, `toMap()`, `fromMap()`, `getKey()`, `setKey()`
- Use static `query()` method for fluent query building
- Support timestamps, soft deletes, and relationships via mixins

### 7. Validation Pattern

Validation rules are composable classes:
- Each rule extends `ValidationRule` with `name` and `validate()`
- Fields collect rules via `.rule()` method or convenience methods (`.required()`, `.email()`)
- Validation runs through `FormSchema.validate()` returning field → error maps

### 8. Query Builder Pattern

Fluent interface for database operations:
- Chain methods: `where()`, `orderBy()`, `limit()`, `offset()`
- Execute with: `get()`, `first()`, `count()`, `insert()`, `update()`, `delete()`
- `ModelQueryBuilder` wraps base builder to return typed model instances

## Do's and Don'ts

### ✅ Do
- Use fluent builder APIs for all configuration
- Provide `make()` factory methods
- Follow the established naming conventions
- Use Alpine.js for client-side interactivity
- Create reusable Jaspr components for UI elements
- Write tests for new functionality
- Use generics to preserve types through method chains
- Keep components focused (single responsibility)
- Use Heroicons for icons
- Put type conversion logic in `dehydrateValue()` on field classes
- Use Playwright for interactive testing and bug reproduction

### ❌ Don't
- Don't hardcode strings - use configuration methods
- Don't create one-off inline styles - use Tailwind classes
- Don't skip the `make()` factory pattern for configurable classes
- Don't put field type conversion logic in Resource - fields own their conversion
- Don't assume foreign key types - use model schema to determine column types
- Don't use Dart mirrors/reflection - use direct method calls or fallback patterns

---

*Last updated: 2025-12-06*
