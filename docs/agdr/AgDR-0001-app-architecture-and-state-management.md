# Clean Architecture + Riverpod for State Management

> In the context of building a Flutter mobile ToDo app, facing the need for a testable, maintainable codebase, I decided to use clean architecture layers with Riverpod for state management to achieve clear separation of concerns, accepting the upfront ceremony of defining domain/data/application/presentation layers.

## Context

- Flutter app targeting iOS + Android
- Local-only offline storage (no cloud sync)
- Need >80% domain test coverage per ApexYard gate
- Solo maintainer — ceremony should pay off in testability, not team coordination

## Options Considered

| Option | Pros | Cons |
|--------|------|------|
| Clean architecture + Riverpod | Testable domain layer (no Flutter deps), familiar in Flutter ecosystem, code generation with riverpod_generator, excellent DI story | More boilerplate than plain setState |
| BLoC | Mature, explicit event/state model | Heavier boilerplate, less ergonomic for simple apps |
| Provider | Simple | Deprecated in favour of Riverpod by the same author |
| setState / ValueNotifier | Zero boilerplate | No DI, no testability beyond widget tests |

## Decision

Chosen: **Clean architecture layers + Riverpod**, because:
- Domain layer (no Flutter/DB imports) is trivially unit-testable
- Riverpod providers serve as the application layer, bridging domain and presentation
- `riverpod_generator` reduces boilerplate to annotated functions/classes
- Aligns with ApexYard code-standards: domain layer has no external dependencies

## Layer contract

```
lib/
  domain/       # Todo entity, TodoRepository abstract class — NO Flutter/DB imports
  data/         # Drift table, DriftTodoRepository (implements TodoRepository), mappers
  application/  # Riverpod providers/notifiers (use-case logic)
  presentation/ # screens, widgets
  main.dart
```

## Consequences

- `lib/domain/` is a pure Dart package — any change that adds a Flutter import breaks the contract
- Repository interface lives in domain; concrete impl lives in data — swapping DB requires only a data-layer change
- All provider tests can run without a Flutter test host (`dart test`)

## Artifacts

- Initial scaffold PR: ahmed-faruk/todo-app (initial commit)
