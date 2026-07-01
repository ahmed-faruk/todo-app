import 'todo.dart';

abstract interface class TodoRepository {
  Stream<List<Todo>> watchAll();
  Future<void> create(String title);
  Future<void> toggle(int id);
  Future<void> delete(int id);
}
