import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/drift_todo_repository.dart';
import '../domain/todo.dart';
import '../domain/todo_repository.dart';

enum TodoFilter { all, active, completed }

// Non-autoDispose Provider: lives for the entire ProviderScope lifetime.
// onDispose closes the SQLite connection when the scope (app) is destroyed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final todoRepositoryProvider = Provider<TodoRepository>(
  (ref) => DriftTodoRepository(ref.watch(appDatabaseProvider)),
);

final todoListProvider = StreamProvider<List<Todo>>(
  (ref) => ref.watch(todoRepositoryProvider).watchAll(),
);

final filterProvider = StateProvider<TodoFilter>((_) => TodoFilter.all);

final filteredTodoListProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  final all = ref.watch(todoListProvider);
  final filter = ref.watch(filterProvider);
  return all.whenData(
    (todos) => switch (filter) {
      TodoFilter.all => todos,
      TodoFilter.active => todos.where((t) => !t.isCompleted).toList(),
      TodoFilter.completed => todos.where((t) => t.isCompleted).toList(),
    },
  );
});

final todoNotifierProvider = Provider<_TodoNotifier>(
  (ref) => _TodoNotifier(ref.watch(todoRepositoryProvider)),
);

class _TodoNotifier {
  const _TodoNotifier(this._repo);
  final TodoRepository _repo;

  Future<void> add(String title) => _repo.create(title);
  Future<void> toggle(int id) => _repo.toggle(id);
  Future<void> rename(int id, String newTitle) => _repo.rename(id, newTitle);
  Future<void> delete(int id) => _repo.delete(id);
  Future<void> reorder(List<int> orderedIds) => _repo.reorder(orderedIds);
}
