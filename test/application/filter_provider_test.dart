import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/application/providers.dart';
import 'package:todo_app/data/app_database.dart';
import 'package:todo_app/data/drift_todo_repository.dart';
import 'package:todo_app/domain/todo.dart';
import 'package:todo_app/domain/todo_repository.dart';

ProviderContainer _makeContainer() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = DriftTodoRepository(db);
  return ProviderContainer(
    overrides: [
      todoRepositoryProvider.overrideWithValue(repo as TodoRepository),
    ],
  );
}

// Helper: apply filter logic to a list (mirrors providers.dart filteredTodoListProvider)
List<Todo> applyFilter(List<Todo> todos, TodoFilter filter) => switch (filter) {
  TodoFilter.all => todos,
  TodoFilter.active => todos.where((t) => !t.isCompleted).toList(),
  TodoFilter.completed => todos.where((t) => t.isCompleted).toList(),
};

void main() {
  group('TodoFilter enum + filter logic', () {
    test('all filter passes every todo through', () {
      final todos = [
        Todo(id: 1, title: 'A', isCompleted: false, createdAt: DateTime(2024)),
        Todo(id: 2, title: 'B', isCompleted: true, createdAt: DateTime(2024)),
      ];
      expect(applyFilter(todos, TodoFilter.all), hasLength(2));
    });

    test('active filter keeps only incomplete todos', () {
      final todos = [
        Todo(id: 1, title: 'A', isCompleted: false, createdAt: DateTime(2024)),
        Todo(id: 2, title: 'B', isCompleted: true, createdAt: DateTime(2024)),
      ];
      final result = applyFilter(todos, TodoFilter.active);
      expect(result, hasLength(1));
      expect(result.first.title, 'A');
    });

    test('completed filter keeps only completed todos', () {
      final todos = [
        Todo(id: 1, title: 'A', isCompleted: false, createdAt: DateTime(2024)),
        Todo(id: 2, title: 'B', isCompleted: true, createdAt: DateTime(2024)),
      ];
      final result = applyFilter(todos, TodoFilter.completed);
      expect(result, hasLength(1));
      expect(result.first.title, 'B');
    });

    test('active filter on all-completed list returns empty', () {
      final todos = [
        Todo(
          id: 1,
          title: 'Done',
          isCompleted: true,
          createdAt: DateTime(2024),
        ),
      ];
      expect(applyFilter(todos, TodoFilter.active), isEmpty);
    });

    test('completed filter on all-incomplete list returns empty', () {
      final todos = [
        Todo(
          id: 1,
          title: 'Todo',
          isCompleted: false,
          createdAt: DateTime(2024),
        ),
      ];
      expect(applyFilter(todos, TodoFilter.completed), isEmpty);
    });
  });

  group('filterProvider', () {
    test('defaults to all', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      expect(c.read(filterProvider), TodoFilter.all);
    });

    test('can be updated to active', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(filterProvider.notifier).state = TodoFilter.active;
      expect(c.read(filterProvider), TodoFilter.active);
    });

    test('can be updated to completed', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(filterProvider.notifier).state = TodoFilter.completed;
      expect(c.read(filterProvider), TodoFilter.completed);
    });
  });
}
