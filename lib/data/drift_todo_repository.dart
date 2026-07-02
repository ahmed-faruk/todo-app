import 'package:drift/drift.dart';

import '../domain/todo.dart';
import '../domain/todo_repository.dart';
import 'app_database.dart';

class DriftTodoRepository implements TodoRepository {
  const DriftTodoRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Todo>> watchAll() {
    return (_db.select(_db.todoItems)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<void> create(String title) async {
    await _db.transaction(() async {
      final minOrder =
          await (_db.selectOnly(_db.todoItems)
                ..addColumns([_db.todoItems.sortOrder.min()]))
              .map((row) => row.read(_db.todoItems.sortOrder.min()))
              .getSingleOrNull();
      final nextOrder = (minOrder ?? 0) - 1;
      await _db
          .into(_db.todoItems)
          .insert(
            TodoItemsCompanion.insert(
              title: title,
              sortOrder: Value(nextOrder),
            ),
          );
    });
  }

  @override
  Future<void> reorder(List<int> orderedIds) async {
    await _db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.todoItems)
              ..where((t) => t.id.equals(orderedIds[i])))
            .write(TodoItemsCompanion(sortOrder: Value(i)));
      }
    });
  }

  @override
  Future<void> toggle(int id) async {
    // Read current value then flip — Drift doesn't support column-expression updates
    // without a custom statement, so we fetch + write in a transaction.
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.todoItems,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) return;
      await (_db.update(_db.todoItems)..where((t) => t.id.equals(id))).write(
        TodoItemsCompanion(isCompleted: Value(!row.isCompleted)),
      );
    });
  }

  @override
  Future<void> rename(int id, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;
    await (_db.update(_db.todoItems)..where((t) => t.id.equals(id))).write(
      TodoItemsCompanion(title: Value(trimmed)),
    );
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.todoItems)..where((t) => t.id.equals(id))).go();
  }

  Todo _toEntity(TodoItem row) => Todo(
    id: row.id,
    title: row.title,
    isCompleted: row.isCompleted,
    createdAt: row.createdAt,
    sortOrder: row.sortOrder,
  );
}
