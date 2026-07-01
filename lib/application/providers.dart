import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/drift_todo_repository.dart';
import '../domain/todo.dart';
import '../domain/todo_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>(
  (_) => AppDatabase(),
  // Keep the DB alive for the lifetime of the app
);

final todoRepositoryProvider = Provider<TodoRepository>(
  (ref) => DriftTodoRepository(ref.watch(appDatabaseProvider)),
);

final todoListProvider = StreamProvider<List<Todo>>(
  (ref) => ref.watch(todoRepositoryProvider).watchAll(),
);

final todoNotifierProvider =
    Provider<_TodoNotifier>((ref) => _TodoNotifier(ref.watch(todoRepositoryProvider)));

class _TodoNotifier {
  const _TodoNotifier(this._repo);
  final TodoRepository _repo;

  Future<void> add(String title) => _repo.create(title);
  Future<void> delete(int id) => _repo.delete(id);
}
