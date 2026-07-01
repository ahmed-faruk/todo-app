# todo_app

A cross-platform (iOS + Android) offline ToDo app built with Flutter, Riverpod,
and Drift (SQLite). Governed by the ApexYard SDLC framework.

## Architecture

Clean architecture layers under `lib/`:

- `domain/` — `Todo` entity + `TodoRepository` interface (pure Dart, no Flutter/DB imports)
- `data/` — Drift database + `DriftTodoRepository` implementation
- `application/` — Riverpod providers (todo list, filter, mutations)
- `presentation/` — screens and widgets

Architecture decisions: `docs/agdr/`.

## Development

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate Drift code
flutter run
```

### Pre-push checks (required)

CI (`.github/workflows/flutter-ci.yml`) enforces formatting, analysis, and tests.
Enable the local pre-push hook once per clone so drift is caught before it turns CI red:

```bash
git config core.hooksPath .githooks
```

The hook runs `dart format --set-exit-if-changed`, `flutter analyze`, and `flutter test`.
