import 'todo.dart';

abstract interface class TodoRepository {
  Stream<List<Todo>> watchAll();
  Future<void> create(String title);
  Future<void> delete(int id);
}
