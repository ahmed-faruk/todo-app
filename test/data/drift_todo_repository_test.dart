import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/app_database.dart';
import 'package:todo_app/data/drift_todo_repository.dart';

void main() {
  late AppDatabase db;
  late DriftTodoRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTodoRepository(db);
  });

  tearDown(() => db.close());

  group('DriftTodoRepository', () {
    test('watchAll emits empty list on fresh DB', () async {
      final todos = await repo.watchAll().first;
      expect(todos, isEmpty);
    });

    test('create adds a todo that appears in watchAll', () async {
      await repo.create('Walk the dog');
      final todos = await repo.watchAll().first;
      expect(todos, hasLength(1));
      expect(todos.first.title, 'Walk the dog');
      expect(todos.first.isCompleted, isFalse);
    });

    test('create multiple todos, all appear in watchAll', () async {
      await repo.create('First');
      await repo.create('Second');
      final todos = await repo.watchAll().first;
      expect(todos, hasLength(2));
      expect(todos.map((t) => t.title), containsAll(['First', 'Second']));
    });

    test('delete removes the todo', () async {
      await repo.create('Temporary');
      final before = await repo.watchAll().first;
      expect(before, hasLength(1));

      await repo.delete(before.first.id);
      final after = await repo.watchAll().first;
      expect(after, isEmpty);
    });

    test('delete non-existent id is a no-op', () async {
      await repo.create('Stays');
      await repo.delete(9999);
      final todos = await repo.watchAll().first;
      expect(todos, hasLength(1));
    });
  });
}
