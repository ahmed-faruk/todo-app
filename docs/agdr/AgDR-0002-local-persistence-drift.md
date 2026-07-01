# Local Persistence: Drift (SQLite)

> In the context of offline-only Flutter ToDo storage, facing the choice of local DB library, I decided to use Drift (formerly Moor) to achieve type-safe SQL with migrations, accepting the code-generation build step.

## Context

- Offline-only; no cloud sync in scope
- Need durable persistence across app restarts
- Need schema migrations (as schema evolves with new features)
- AgDR-0001 mandates repository pattern — persistence detail must be in the data layer only

## Options Considered

| Option | Pros | Cons |
|--------|------|------|
| **Drift** | Type-safe queries, migrations out of the box, reactive streams, good Flutter integration | Build step (`build_runner`), slightly more complex setup |
| Isar | Fast, NoSQL, native, no migrations needed for simple shapes | Migration story weaker for relational/SQL data, less mature |
| Hive | Simple key-value, fast | No relations, no migrations, weak type safety |
| sqflite raw | Minimal, well-understood | Raw SQL strings, no type safety, migrations are manual |

## Decision

Chosen: **Drift**, because:
- Type-safe table definitions and queries (compile-time errors on schema mismatches)
- Built-in migration API with `MigrationStrategy` — critical as the schema grows
- Returns `Stream<List<Todo>>` — reactive UI updates without manual polling
- Backed by sqflite/SQLite — mature and battle-tested on iOS + Android
- Aligns with repository pattern: `DriftTodoRepository` implements `TodoRepository` from domain

## Consequences

- `build_runner` required during development (`dart run build_runner watch`)
- Generated files (`*.g.dart`) committed to source control (convention for Drift projects)
- Data layer depends on `drift` package; domain layer remains import-free

## pubspec.yaml additions

```yaml
dependencies:
  drift: ^2.x
  sqlite3_flutter_libs: ^0.5.x
  path_provider: ^2.x
  path: ^1.x
  riverpod_annotation: ^2.x
  flutter_riverpod: ^2.x

dev_dependencies:
  drift_dev: ^2.x
  build_runner: ^2.x
  riverpod_generator: ^2.x
```

## Artifacts

- This AgDR — committed before any DB code is written (per workflow-gates.md Gate 2)
